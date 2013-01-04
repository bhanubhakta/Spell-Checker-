class SpellCheck
	attr_accessor :year, :ed1_tot_freq, :ed2_tot_freq, :typed_word, :count_ed1, :count_ed2
	attr_reader :dictionary , :score , :suggestion_list 
  
  def initialize(name, year)
    @name = name
    @year = year
    @dictionary = {}
    @score = []
    @suggestion_list = []
    filename = year.to_s + ".txt"
    
  end

  # For the selection of year...
	# def useyear(year)
	# 	@year = year 
	# end

  # For user 
	def add_hash_to_dictionary(options)
    @dictionary = options.merge(@dictionary)
	end

  # For adding CSV file to dictionary
  # def add_file_to_dictionary()
  # end
end

spellcheck = SpellCheck.new("bhanu", 1990)

# spellcheck.add_hash_to_dictionary(:apple => "fruit", :mango => "fruit", :cauliflower => "vegitable")


# p spellcheck.test