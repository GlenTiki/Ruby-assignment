require 'sequel'
require 'sqlite3'
require 'logger'
require_relative 'book_in_stock'

  class DataBase 
  
  def initialize (db_path)
      @db_path = db_path
      @DB_ref = nil
  end
  
  def start 
  	 @DB_ref = Sequel.sqlite(@db_path ) 
     @DB_ref.loggers << Logger.new($stdout)
  end

  def stop
  end

  def findISBN isbn
     dataset = @DB_ref[:books].where(:isbn => isbn)
     objects = object_relational_mapper dataset
     objects[0]
  end

  def authorSearch(author)
  	  dataset = @DB_ref[:books].where(:author => author)
      object_relational_mapper dataset
  end

  def updateBook book
     books = @DB_ref[:books].where(:isbn => book.isbn)
     books.update(:author => book.author, 
                 :genre => book.genre,
                 :title => book.title, 
                 :price => book.price, 
                 :quantity => book.quantity)
  end

  def createBook book
    @DB_ref[:books].insert(:isbn => book.isbn,
      :title => book.title, :author=> book.author,
      :genre => book.genre, :price => book.price,
      :quantity=> book.quantity)
  end

  def deleteBook isbn
    @DB_ref[:books].where(:isbn => isbn).delete
  end

  def genreSearch(genre)
      dataset = @DB_ref[:books].where(:genre => genre)
      object_relational_mapper dataset
  end

  def getBooks
    dataset = @DB_ref[:books]
    object_relational_mapper dataset
  end

private

  def object_relational_mapper dataset
    books = []
    dataset.each do |d|
      books << BookInStock.new(d[:isbn], d[:title],
                               d[:author],d[:genre],
                               d[:price], d[:quantity])
    end
    books
  end

end 