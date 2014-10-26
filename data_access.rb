require_relative 'book_in_stock'
require_relative 'database'
require_relative 'shared_cache'
require 'dalli'

class DataAccess 
  
  def initialize db_path
    @database = DataBase.new db_path
    @shared_cache = SharedCache.new
    @local_cache = Hash.new
  end
    
  def start 
    @shared_cache.start
    @database.start 
  end

  def stop
  end

  def findISBN isbn
    rtn = ""
    begin
      local_version = @local_cache["v_#{isbn}"]
      if(!local_version) 
        raise "not in local cache"
      end
      if(local_version >= @shared_cache.getVersion(isbn))
        rtn = @local_cache["#{local_version}_#{isbn}"]
        if(local_version > @shared_cache.getVersion(isbn))
          book_in_database = @database.findISBN isbn
          if book_in_database
            @shared_cache.updateBook(book_in_database)
            new_version = @shared_cache.getVersion isbn
            @local_cache["v_#{isbn}"] = new_version
            @local_cache["#{new_version}_#{isbn}"] = book_in_database
            @local_cache["#{local_version}_#{isbn}"] = nil
            update_complex_entities book_in_database
          else
            raise "book has been deleted from the database from another running application, nothing should be returned"
          end
        end
      else
        @local_cache["#{local_version}_#{isbn}"] = nil
        raise "in local cache but out of date"
      end
    rescue
      begin
        rtn = @shared_cache.findISBN isbn
        if rtn.isbn != isbn 
          raise "not in shared cache"
        else
          local_version = @shared_cache.getVersion isbn
          @local_cache["v_#{isbn}"] = local_version
          @local_cache["#{local_version}_#{isbn}"] = rtn
          update_complex_entities @local_cache["#{local_version}_#{isbn}"]
        end
      rescue
        rtn = @database.findISBN isbn
        if rtn
          @shared_cache.createBook rtn
          @local_cache["v_#{isbn}"] = 1
          @local_cache["#{1}_#{isbn}"] = rtn
          update_complex_entities rtn
        end
      end
    end
    rtn      
  end

  def authorSearch author
    rtn = []
    begin
      books_by_author = @local_cache["bks_#{author}"]
      if(!books_by_author) 
        raise "none in local cache"
      end
      complex_entity_key = "#{author}"
      books_by_author.each do |isbn|
        version = getVersion isbn
        complex_entity_key += "_#{isbn}_#{version}"
      end
      rtn = @local_cache[complex_entity_key]
      shared_cache_books = @shared_cache.authorSearch(author)
      shared_cache_books.each do |book|
        if((rtn.include?(book)))
          old_version = @local_cache["v_#{book.isbn}"]
          new_version = @shared_cache.getVersion book.isbn
          @local_cache["v_#{book.isbn}"] = new_version
          @local_cache["#{new_version}_#{book.isbn}"] = book
          update_complex_entities book
          @local_cache["#{old_version}_#{book.isbn}"] = nil
          rtn.push book
        end
      end
      database_books = @database.authorSearch(author)
      database_books.each do |book|
        if((rtn.include?(book)))
          @shared_cache.updateBook book
          old_version = @local_cache["v_#{book.isbn}"]
          new_version = @shared_cache.getVersion book.isbn
          @local_cache["v_#{book.isbn}"] = new_version
          @local_cache["#{new_version}_#{book.isbn}"] = book
          update_complex_entities book
          @local_cache["#{old_version}_#{book.isbn}"] = nil
          rtn.push book
        end
      end
    rescue
      begin
        rtn = @shared_cache.authorSearch author
        if rtn
          rtn.each do |book|
            old_version = @local_cache["v_#{book.isbn}"]
            new_version = @shared_cache.getVersion book.isbn
            @local_cache["v_#{book.isbn}"] = new_version
            @local_cache["#{new_version}_#{book.isbn}"] = book
            update_complex_entities book
            @local_cache["#{old_version}_#{book.isbn}"] = nil
          end
          database_books = @database.authorSearch(author)
          database_books.each do |book|
            if((rtn.include?(book)))
              @shared_cache.updateBook book
              old_version = @local_cache["v_#{book.isbn}"]
              new_version = @shared_cache.getVersion book.isbn
              @local_cache["v_#{book.isbn}"] = new_version
              @local_cache["#{new_version}_#{book.isbn}"] = book
              update_complex_entities book
              @local_cache["#{old_version}_#{book.isbn}"] = nil
              rtn.push book
            end
          end
        else
          raise "not in shared cache"
        end
      rescue
        rtn = @database.authorSearch author
        if rtn
          rtn.each do |book|
            @shared_cache.updateBook book
            old_version = @local_cache["v_#{book.isbn}"]
            new_version = @shared_cache.getVersion book.isbn
            @local_cache["v_#{book.isbn}"] = new_version
            @local_cache["#{new_version}_#{book.isbn}"] = book
            update_complex_entities book
            @local_cache["#{old_version}_#{book.isbn}"] = nil
          end
        end
      end
    end
    rtn 
  end

  def updateBook book
    books = @local_cache["bks_#{book.author}"]
    if books
      complex_entity_key = "#{book.author}"
      books.each do |isbns|
        version = getVersion isbns
        complex_entity_key += "_#{isbns}_#{version}"
      end
      @local_cache[complex_entity_key] = nil
    end

    books = @local_cache["bks_#{book.genre}"]
    if books
      complex_entity_key = "#{book.genre}"
      books.each do |isbns|
        version = getVersion isbns
        complex_entity_key += "_#{isbns}_#{version}"
      end
      @local_cache[complex_entity_key] = nil
    end

    @shared_cache.updateBook book
    old_version = @local_cache["v_#{book.isbn}"]
    new_version = @shared_cache.getVersion book.isbn
    @local_cache["v_#{book.isbn}"] = new_version
    @local_cache["#{new_version}_#{book.isbn}"] = book
    update_complex_entities book
    @database.updateBook book
    @local_cache["#{old_version}_#{book.isbn}"] = nil
  end

  def createBook book
    books = @local_cache["bks_#{book.author}"]
    if books
      complex_entity_key = "#{book.author}"
      books.each do |isbns|
        version = getVersion isbns
        complex_entity_key += "_#{isbns}_#{version}"
      end
      @local_cache[complex_entity_key] = nil
    end

    books = @local_cache["bks_#{book.genre}"]
    if books
      complex_entity_key = "#{book.genre}"
      books.each do |isbns|
        version = getVersion isbns
        complex_entity_key += "_#{isbns}_#{version}"
      end
      @local_cache[complex_entity_key] = nil
    end

    @shared_cache.createBook book
    old_version = @local_cache["v_#{book.isbn}"]
    new_version = @shared_cache.getVersion book.isbn
    @local_cache["v_#{book.isbn}"] = new_version
    @local_cache["#{old_version}_#{book.isbn}"] = nil
    @local_cache["#{new_version}_#{book.isbn}"] = book
    update_complex_entities book
    @database.createBook book
  end

  def deleteBook isbn
    old_version = @local_cache["v_#{isbn}"]
    book = @local_cache["#{old_version}_#{isbn}"]
    if(book)
      books = @local_cache["bks_#{book.author}"]
      if books
        complex_entity_key = "#{book.author}"
        books.each do |isbns|
          version = getVersion isbns
          complex_entity_key += "_#{isbns}_#{version}"
        end
        @local_cache[complex_entity_key] = nil
      end

      books = @local_cache["bks_#{book.genre}"]
      if books
        complex_entity_key = "#{book.genre}"
        books.each do |isbns|
          version = getVersion isbns
          complex_entity_key += "_#{isbns}_#{version}"
        end
        @local_cache[complex_entity_key] = nil
      end
    end
    @shared_cache.deleteBook isbn
    @local_cache["v_#{isbn}"] = nil
    if(book)
      update_complex_entities book
    end
    @local_cache["#{old_version}_#{isbn}"] = nil
    @database.deleteBook isbn
  end

  def getBooks
    @database.getBooks
  end

  def getVersion isbn
    rtn = @local_cache["v_#{isbn}"]
    if(!rtn) 
      rtn = 0 
    end
    rtn
  end

  def update_complex_entities book
    books_by_author = @local_cache["bks_#{book.author}"]
    if books_by_author
      books_by_author.delete_if{|isbn| getVersion(isbn) < 1}
    end
    if books_by_author
      if(!(books_by_author.include?(book.isbn)) and getVersion(book.isbn) > 0) 
        books_by_author.push book.isbn 
      end
    else
      if getVersion(book.isbn) > 0
        books_by_author = [book.isbn]
      else
        books_by_author = []
      end
    end
    @local_cache["bks_#{book.author}"] = books_by_author
    if(books_by_author.length > 0)
      complex_entity_key = "#{book.author}"
      complex_entity_books = []
      books_by_author.each do |isbn|
        version = getVersion isbn
        complex_entity_key += "_#{isbn}_#{version}"
        complex_entity_books.push @local_cache["#{version}_#{isbn}"]
      end
      @local_cache[complex_entity_key] = complex_entity_books
    end



    books_by_genre = @local_cache["bks_#{book.genre}"]
    if books_by_genre
      books_by_genre.delete_if{|isbn| getVersion(isbn) < 1}
    end
    if books_by_genre
      if(!(books_by_genre.include?(book.isbn)) and getVersion(book.isbn) > 0) 
        books_by_genre.push book.isbn 
      end
    else
      if getVersion(book.isbn) > 0
        books_by_genre = [book.isbn]
       else
        books_by_genre = []
      end
    end
    
    @local_cache["bks_#{book.genre}"] = books_by_genre

    if(books_by_genre.length > 0)
      complex_entity_key = "#{book.genre}"
      complex_entity_books = []
      books_by_genre.each do |isbn|
        version = getVersion isbn
        complex_entity_key += "_#{isbn}_#{version}"
        complex_entity_books.push @local_cache["#{version}_#{isbn}"]
      end
      @local_cache[complex_entity_key] = complex_entity_books
    end
  end

end 