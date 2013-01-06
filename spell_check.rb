require 'csv'

class SpellCheck
	attr_accessor :typed_name, :count_ed1, :count_ed2, :ed1, :ed2, :weight_ed1, :weight_ed2
	attr_reader :working_dictionary, :suggestion, :ed1_tot_freq, :ed2_tot_freq, :total_freq, :year
  @@LETTERS
  @@dictionary
  
  def initialize(name)
    @typed_name = name.downcase
    @@dictionary = Hash.new(Hash.new)
    @working_dictionary = Hash.new
    @ed1_tot_freq = 0.0
    @ed2_tot_freq = 0.0
    @total_freq = 0.0
    @count_ed1 = 0
    @count_ed2 = 0
    @weight_ed1 = 1
    @weight_ed2 = 0.1
    @suggestion = []
    @year = []
    @@LETTERS = ("a".."z").to_a.join
    
    bulk_import # import name & freq from all files
    create_csv  # create a CSV file with title only
  end

  # Add which year is inserted in the @working_dictionary
  def add_year year
    @year.push(year)
  end

  #To import all the CSV files from a directory
  def bulk_import 
    location = "./US_birth_name_frequencies/"
    dir_contents = Dir.entries(location)
    dir_contents = dir_contents.sort!
    dir_contents = dir_contents[2..dir_contents.length-1]
    dir_contents.each do |file_name|
    add_to_dictionary(location,file_name)
    end
  end

  def add_to_dictionary(location, file_name)
    year = file_name.split(".")
    year = (year[0][3..year[0].length-1])
    dict_by_year = add_file_to_dictionary(File.new(location+file_name).read)
    @@dictionary[year.to_i] = dict_by_year
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
    return dict_by_year
  end

  #Add the name and frequency by year to the working_dictionary
  def add_year_to_dictionary year
    add_year(year)
    temp_dict = @@dictionary[year]
    temp_dict.each do |key, value|
      #Remove the dublicate entry of name and add the frequency while building the HASH
      if @working_dictionary.has_key?(key)  
        @working_dictionary[key] = (value + @working_dictionary[key])
      else
        @working_dictionary[key] = value
      end
    end
  end

  def edits1 word
    n = word.length
    deletion = (0...n).collect {|i| word[0...i]+word[i+1..-1] }
    transposition = (0...n-1).collect {|i| word[0...i]+word[i+1,1]+word[i,1]+word[i+2..-1] }
    alteration = []
    n.times {|i| @@LETTERS.each_byte {|l| alteration << word[0...i]+l.chr+word[i+1..-1] } }
    insertion = []
    (n+1).times {|i| @@LETTERS.each_byte {|l| insertion << word[0...i]+l.chr+word[i..-1] } }
    result = deletion + transposition + alteration + insertion
    result.empty? ? nil : result
  end

  def known_edits2 word
    result = []
    edits1(word).each {|e1| 
      edits1(e1).each {|e2| 
        result << e2 if working_dictionary.has_key?(e2) 
      }
    }
    result.empty? ? nil : result
  end

  def known words
    result = words.find_all {|w| working_dictionary.has_key?(w) }
    result.empty? ? nil : result
  end

  #Finds the top five suggestion from edit distance one and two,
  #accoring to their scores.
  def select_top_five  
    if(@ed1 == nil)
      words = @ed2 
    elsif(@ed2 == nil)
      words = @ed1
    else
      words = @ed1.merge(@ed2)
    end
    words = words.sort_by{|k,v| -v}.first 5
    words = Hash[*words.flatten]
    final_list = Hash.new{}
    # If the typed_word isnt in the dictionary, replace 5th suggestion by typed_word 
    if !working_dictionary.has_key?( @typed_name )
        words.each_with_index { |(k,v),index|
          if index == (words.length-1)
            final_list[@typed_name] = v*0.5
          else
            final_list[k] = v
          end
        }
        words = final_list
    end
    @suggestion = words
    return words       #Hash of words and corresponding score 
  end

  # Calculates the socre for each edit distance suggestion list
  def calc_score(words, total_freq, weight)
    hash = Hash.new{}
    words.each{|w|
      s = (weight * working_dictionary[w]/(total_freq*words.length)*100).round(4)
      hash[w] = s   
    }
    hash = hash.sort_by{|k,v| -v} 
    hash = Hash[*hash.flatten]
    return hash
  end

  def sort_top_n_words_by_frequency(words, n)
    unless words.nil?
      sorted_words = words.sort_by{|w| -working_dictionary[w] }
      array = sorted_words.first n
      return array
    end
  end

  def correct
    # Get list non-repeated words with edit distances ONE
    unless (@ed1 = (known(edits1( @typed_name )))).nil?
      @ed1 = (known(edits1( @typed_name ))).uniq
      @count_ed1 = @ed1.length
    end 
    # Get list non-repeated words with edit distances TWO
    unless (e2 = (known_edits2( @typed_name ))).nil? 
      @ed2 = (known_edits2( @typed_name )).uniq
      @count_ed2 = @ed2.length
    end
    # Ignore words with @ed2 for the word length of THREE
    if( @typed_name.length<= 3)
      @ed2 = nil
    end

    # Sort the words in list accoring to frequency and grab only top 10 words
    @ed1 =sort_top_n_words_by_frequency(@ed1,10)
    @ed2 = sort_top_n_words_by_frequency(@ed2,10)

    # Remove the words from @ed2 which already appeared @ed1
    unless @ed1.nil?
    unless @ed2.nil?
      edit2 = []
      @ed2.each {|w|
          if !@ed1.include?(w) 
            edit2.push(w) 
           end   
      }
      @ed2 = edit2
    end
    end

    # Calculate total frequency for @ed1 array
    unless @ed1.nil?
      @ed1.each{|w|
        @ed1_tot_freq += working_dictionary[w]
      }
    end

    # Calculate total frequency for @ed2 array
    unless @ed2.nil?
      @ed2.each{|w|
      @ed2_tot_freq += working_dictionary[w]
    }
    end
    # total frequency of @ed1 & @ed2
    @total_freq = @ed1_tot_freq + @ed2_tot_freq

    # Calculate score for each words in @ed1
    unless @ed1.nil?
      @ed1 = calc_score(@ed1, @ed1_tot_freq, @weight_ed1) 
    end

    # Calculate score for each words in @ed1
    unless @ed2.nil?
      @ed2 = calc_score(@ed2, @ed2_tot_freq, @weight_ed2)
    end

    # Select top five suggestions from @ed1 & @ed1 
    select_top_five
  end  

  # Create CSV file with title only
  def create_csv
    title = ["Typed Word","Suggestion", "Score", "Frequency", "ED?", "Count ED", "Year"]
    CSV.open('output.csv', 'a') do |csv|
      csv << title
    end
  end

  # Append a line in CSV file ||Typed Name||Suggestion||Score||Frequency||ED||Count ED||
  def export_csv
    correct
    CSV.open('output.csv', 'a') do |csv|
      @suggestion.each_with_index{|(name,score), index|
        word =  @typed_name.capitalize                  #typed name
        sugges = name.capitalize                        #suggestion name
        score = (@suggestion[name].round(3)).to_s       #score of this suggestion
        years = @year                                   #which years are inserted to dictionary
        ed = "NA"                                       #which ED this name belongs to
        ed_count = "NA"                                 #how many candidates fall in ED of this name

        # Check frequency for the words in suggestion list
        # Typed word, not in the dictionary has zero frequency
        if @working_dictionary.has_key?(name)
          freq = (@working_dictionary[name]).to_s  
        else
          freq = 0
        end
        
        # Check which edit distance the word belongs to.

        # Check if the word is from @ed1
        if !@ed1.nil?
          if @ed1.include?(name)
            ed = 1.to_s
            ed_count = @count_ed1.to_s
          end
        end

        # Check if the word is from @ed2
        if !@ed2.nil?
          if @ed2.include?(name)
            ed = 2.to_s
            ed_count = @count_ed2.to_s
          end  
        end

        # Build a string to insert in csv file
        if index == 0    # years are displayed only in first line for this @typed_name
          line = [word, sugges, score, freq, ed, ed_count, year]  
        else
          line = [word, sugges, score, freq, ed, ed_count]  
        end

        csv << line
      }
      csv << []  # insert blank line as last line
    end
  end

end

#List of test typed names
test_case = ['Dalila','Haelen','Haabel','Marrk','Maccy','Hlen','Egenia','acy',
            'Dcire','Hleen','Mable','Dicei','Hilin','Mabal','Maoy','Dlcie',
            'Dark','Rogert','Decei','roth','rosa','evan','jelma','alv', 'rose']

# test_case = ['Dalila'] 

test_case.each{|word|
    spellcheck = SpellCheck.new(word)

    # Choose birth name by multiple year
    spellcheck.add_year_to_dictionary(1990)
    # spellcheck.add_year_to_dictionary(1882)
    # spellcheck.add_year_to_dictionary(1883)
    # spellcheck.add_year_to_dictionary(1884)

    spellcheck.export_csv                 # Export to CSV file
  }

 





