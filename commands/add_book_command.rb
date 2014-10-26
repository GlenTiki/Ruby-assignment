require_relative 'user_command'

class AddBookCommand < UserCommand

	def initialize (data_source)
		super (data_source)
    @isbn = ''
    @author = ''
    @title = ''
    @genre = ''
    @price = 0
    @quantity = 0
	end

	def title 
		'Add Book.'
	end

  def input
    response = ''
   	puts 'Add Book. (Don\'t leave any field blank.)'
	  print "ISBN?\n"
    @isbn = getValidInput 
    print "Author?\n"
    @author = getValidInput 
    print "Title?\n"
    @title = getValidInput
    puts "Genre"
    $GENRE.each_index {|i| print " (#{i+1}) #{$GENRE[i]}"}
    print "?\n"
    response = getValidInput.to_i
    @genre = $GENRE[(response % $GENRE.length) - 1]
    print "price?\n"
    @price = getValidInput.to_f
    print "quantity in stock?\n"
    @quantity = getValidInput.to_i
  end

  def getValidInput
    response = ''
    loop do 
      response = STDIN.gets.chomp 
      break if response.size > 0
      print "please enter something and don't leave this field empty."
    end
    response
  end

  def execute
    book = BookInStock.new(@isbn, @title, @author, @genre, @price, @quantity)
    if book
      begin
        @data_source.createBook book
      rescue
       print 'could not create book. did you have a unique isbn?'
      end
    else
      puts 'Invalid ISBN'
    end
	end 
end
