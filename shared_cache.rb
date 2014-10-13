require 'dalli'
require_relative 'book_in_stock'

  class SharedCache
  
  def initialize
       @Remote_cache = Dalli::Client.new('localhost:11211')
  end
  
  def start 
  end

  def stop
  end

  def findISBN isbn
  end

  def authorSearch(author)
  end

  def updateBook book
  end

  def createBook book
  end

  def deleteBook isbn
  end

  def genreSearch(genre)
  end

  def getBooks
  end
end 


