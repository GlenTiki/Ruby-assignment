require_relative 'book_in_stock'
require_relative 'database'
require_relative 'shared_cache'
require 'dalli'

class DataAccess 
  
    def initialize db_path
       @database = DataBase.new db_path
       @sharedCache = SharedCache.new
       # Relevant data structure(s) for local cache
    end
    
    def start 
       @sharedCache.start
    	 @database.start 
    end

    def stop
    end

    def findISBN isbn
       @database.findISBN isbn       
    end

    def authorSearch(author)
       @database.authorSearch author
    end

    def updateBook book
       @database.updateBook book
    end

    def createBook book
       @database.createBook book
    end

    def deleteBook isbn
       @database.deleteBook isbn
    end

    def getBooks
       @database.getBooks
    end

end 