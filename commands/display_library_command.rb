require_relative 'user_command'

class DisplayLibraryCommand < UserCommand

	def initialize (data_source)
		super (data_source)
		@author = ''
	end

	def title 
		'Display Library.'
	end

   def input
   end

    def execute
       @data_source.getBooks.each {|b| puts b }
	end

end