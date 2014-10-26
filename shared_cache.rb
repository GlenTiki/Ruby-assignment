require 'dalli'
require_relative 'book_in_stock'

  class SharedCache
  
  def initialize
       @remote_cache = Dalli::Client.new('localhost:11211')
  end
  
  def start 
  end

  def stop
  end

  def findISBN isbn
    rtn = nil
    version = getVersion isbn
    serial = @remote_cache.get "#{version}_#{isbn}"
    rtn = BookInStock.from_cache(serial)
    rtn
  end

  def authorSearch(author)
    book_isbns = get_array_from_serialized_data(@remote_cache.get("bks_#{author}"), ',')
    complex_entity_key = "#{author}"
    book_isbns.each do |isbn|
      version = getVersion isbn
      complex_entity_key += "_#{isbn}_#{version}"
    end
    serialised_books_by_author = get_array_from_serialized_data(@remote_cache.get(complex_entity_key), ';')
    books_by_author = []
    serialised_books_by_author.each do |serial|
      books_by_author.push (BookInStock.from_cache serial)
    end
    books_by_author
  end

  def updateBook book
    serialized = @remote_cache.get "bks_#{book.author}"
    if serialized
      complex_entity_key = "#{book.author}"
      book_author_isbns = get_array_from_serialized_data(serialized, ',')
      book_author_isbns.each do |isbn|
        version = getVersion isbn
        complex_entity_key += "_#{isbn}_#{version}"
      end
      @remote_cache.set complex_entity_key, nil
    end

    serialized = @remote_cache.get "bks_#{book.genre}"
    if serialized
      complex_entity_key = "#{book.genre}"
      book_author_isbns = get_array_from_serialized_data(serialized, ',')
      book_author_isbns.each do |isbn|
        version = getVersion isbn
        complex_entity_key += "_#{isbn}_#{version}"
      end
      @remote_cache.set complex_entity_key, nil
    end

    version = getVersion(book.isbn) + 1
    @remote_cache.set "v_#{book.isbn}", version
    @remote_cache.set "#{version}_#{book.isbn}", book.to_cache
    update_complex_entity book
  end

  def createBook book
    updateBook book
  end

  def deleteBook isbn
    version = getVersion(isbn)
    serial = @remote_cache.get("#{version}_#{isbn}")
    book = nil
    if serial
      book = BookInStock.from_cache serial
    end
    if book
      serialized = @remote_cache.get "bks_#{book.author}"
      if serialized
        complex_entity_key = "#{book.author}"
        book_author_isbns = get_array_from_serialized_data(serialized, ',')
        book_author_isbns.each do |isbns|
          version = getVersion isbns
          complex_entity_key += "_#{isbns}_#{version}"
        end
        @remote_cache.set complex_entity_key, nil
      end

      serialized = @remote_cache.get "bks_#{book.genre}"
      if serialized
        complex_entity_key = "#{book.genre}"
        book_author_isbns = get_array_from_serialized_data(serialized, ',')
        book_author_isbns.each do |isbns|
          version = getVersion isbns
          complex_entity_key += "_#{isbns}_#{version}"
        end
        @remote_cache.set complex_entity_key, nil
      end
    end
    @remote_cache.set "v_#{isbn}", 0
    if book
      update_complex_entity(book)
    end
    @remote_cache.set "#{version}_#{isbn}", nil
  end

  def genreSearch(genre)
    book_isbns = get_array_from_serialized_data(@remote_cache.get("bks_#{genre}"), ',')
    complex_entity_key = "#{genre}"
    book_isbns.each do |isbn|
      version = getVersion isbn
      complex_entity_key += "_#{isbn}_#{version}"
    end
    serialised_books_by_genre = get_array_from_serialized_data(@remote_cache.get(complex_entity_key), ';')
    books_by_genre = []
    serialised_books_by_genre.each do |serial|
      books_by_genre.push (BookInStock.from_cache serial)
    end
    books_by_genre
  end

  def getVersion isbn
    rtn = @remote_cache.get "v_#{isbn}"
    if(!rtn) 
      rtn = 0 
    end
    rtn
  end

  def serialize array
    str = ""
      if array
        array.each do|i| 
          str += "#{i.to_str},"
        end
        str = str[0...-1]
      end
    str
  end

  def get_array_from_serialized_data serialized, seperator
    serialized.split(seperator)
  end

  def update_complex_entity book

    serialized = @remote_cache.get "bks_#{book.author}"

    book_author_isbns = []

    if serialized
      book_author_isbns = get_array_from_serialized_data(serialized, ',')

      book_author_isbns.delete_if{|isbn| getVersion(isbn) < 1}
    end

    if(book)
        if(!(book_author_isbns.include?(book.isbn)) and getVersion(book.isbn) > 0) 
          book_author_isbns.push book.isbn 
        end
    end

    @remote_cache.set "bks_#{book.author}", serialize(book_author_isbns)

    if book_author_isbns.length > 0
      complex_entity_key = "#{book.author}"
      complex_entity_entry = ""

      book_author_isbns.each do |isbn|
        version = getVersion isbn
        complex_entity_key += "_#{isbn}_#{version}"
        entry = @remote_cache.get("#{version}_#{isbn}")
        complex_entity_entry += "#{entry};"
      end
      complex_entity_entry = complex_entity_entry[0...-1]
    
      @remote_cache.set complex_entity_key, complex_entity_entry
    end
    serialized = @remote_cache.get "bks_#{book.genre}"

    book_genre_isbns = []

    if serialized
      book_genre_isbns = get_array_from_serialized_data(serialized, ',')
      book_genre_isbns.delete_if{|isbn| getVersion(isbn) < 1}
    end

    if(book)
        if(!(book_genre_isbns.include?(book.isbn)) and getVersion(book.isbn) > 0) 
          book_genre_isbns.push book.isbn 
        end
    end

    @remote_cache.set "bks_#{book.genre}", serialize(book_genre_isbns)
    
    if book_genre_isbns.length > 0
      complex_entity_key = "#{book.genre}"
      complex_entity_entry = ""

      book_genre_isbns.each do |isbn|
        version = getVersion isbn
        complex_entity_key += "_#{isbn}_#{version}"
        entry = @remote_cache.get("#{version}_#{isbn}")
        complex_entity_entry += "#{entry};"
      end
      complex_entity_entry = complex_entity_entry[0...-1]
      @remote_cache.set complex_entity_key, complex_entity_entry
    end
  end
  
end 