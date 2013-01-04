class SpellCheck
	attr_accessor :year, :ed1_tot_freq, :ed2_tot_freq, :typed_word, :count_ed1, :count_ed2
	attr_reader :dictionary , :score , :suggestion_list 
  
  def initialize(name)
    @name = name
    @dictionary = Hash.new(Hash.new)
    @score = []
    @suggestion_list = []
  end

  # For the selection of year...
	# def useyear(year)
	# 	@year = year 
	# end

  # For user 
	# def add_hash_to_dictionary(options)
 #    @dictionary = options.merge(@dictionary)
	# end

  # For adding file instance to dictionary
  def add_to_dictionary(file_name)

    year = file_name.split(".")
    year = year[0][3..year[0].length-1]
    
    dict_by_year = add_file_to_dictionary(File.new(file_name).read)

    @dictionary[year] = dict_by_year

    puts @dictionary

  end

  def add_file_to_dictionary(features)
    dict_by_year = Hash.new{}
    total_freq = 0

    #count total frequency
    features.each_line do |line|
      splits = line.split(",")
      total_freq += Integer(splits[2])
    end

    features.each_line do |line|
      splits = line.split(",")

      #Remove the dublicate entry of name and add the frequency while building the HASH
      if dict_by_year.has_key?(splits[0].downcase)  
        dict_by_year[splits[0].downcase] = ( Integer(splits[2]) + (dict_by_year[splits[0].downcase]*total_freq) ) / Float(total_freq)
      else
        dict_by_year[splits[0].downcase] = Integer(splits[2])/Float(total_freq)
      end
    end
    return dict_by_year.flatten
  end

end

spellcheck = SpellCheck.new("bhanu")
spellcheck.add_to_dictionary("tes1990.txt")
spellcheck.add_to_dictionary("tes1920.txt")


# spellcheck.add_hash_to_dictionary(:apple => "fruit", :mango => "fruit", :cauliflower => "vegitable")
