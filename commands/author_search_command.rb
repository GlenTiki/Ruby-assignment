require_relative 'user_command'

class AuthorSearchCommand < UserCommand

	def initialize (data_source)
		super (data_source)
		@author = ''
	end

	def title 
		'Search by author.'
	end

   def input
   	   puts 'Search by author.'
	   print "author name? "   
	   @author = STDIN.gets.chomp  
   end

    def execute
       @data_source.authorSearch(@author).each {|b| puts b }
	end

end