# Score calculation in this model
#  
#    Score = Frequency/( total_freq * word_count_in_correction_list )

#
def train features
  model = Hash.new{}
  total_freq = 0

  #count total frequency
  features.each_line{|line|
    splits = line.split(",")
    total_freq += Integer(splits[2])
  }
  features.each_line{|line|
    splits = line.split(",")

    #Remove the dublicate entry of name and add the frequency while building the HASH
    if model.has_key?(splits[0].downcase)  
      model[splits[0].downcase] = ( Integer(splits[2]) + (model[splits[0].downcase]*total_freq) ) / Float(total_freq)
    else
      model[splits[0].downcase] = Integer(splits[2])/Float(total_freq)
    end
  }
  return model 
end

#this method is used to full the data from MYSQL Database
def database_connect
  con = Mysql.new('localhost', 'root', 'root', 'dob')
  rs = con.query('select * from name_freq')
  #rs.each_hash{|h| puts h['frequency']}
  con.close
  return rs
end 

NWORDS = train(File.new('US_birth_name_frequencies/yob1882.txt').read)
LETTERS = ("a".."z").to_a.join

#
def edits1 word
  n = word.length
  deletion = (0...n).collect {|i| word[0...i]+word[i+1..-1] }
  transposition = (0...n-1).collect {|i| word[0...i]+word[i+1,1]+word[i,1]+word[i+2..-1] }
  alteration = []
  n.times {|i| LETTERS.each_byte {|l| alteration << word[0...i]+l.chr+word[i+1..-1] } }
  insertion = []
  (n+1).times {|i| LETTERS.each_byte {|l| insertion << word[0...i]+l.chr+word[i..-1] } }
  result = deletion + transposition + alteration + insertion
  result.empty? ? nil : result
end
#
def known_edits2 word
  result = []
  edits1(word).each {|e1| 
    edits1(e1).each {|e2| 
      result << e2 if NWORDS.has_key?(e2) 
    }
  }
  result.empty? ? nil : result
end
#
def known words
  result = words.find_all {|w| NWORDS.has_key?(w) }
  result.empty? ? nil : result
end

def correct word
  unless (e1 = (known(edits1(word)))).nil?
    e1 = (known(edits1(word))).uniq
  end 
  unless (e2 = (known_edits2(word))).nil? 
    e2 = (known_edits2(word)).uniq
  end
  if(word.length<= 3)
    e2 = nil
  end
  puts "Entered Word"
  puts word
  puts
  #puts "Edit Distance 1"
  #print_words(edits1_candidate)
  e1 =sort_words_by_popularity(e1,word)
  #puts "Edit Distance 2"
  #print_words(edits2_candidate)
  e2 = sort_words_by_popularity(e2,word)
  unless e1.nil?
  unless e2.nil?
    edit2 = []
    e2.each {|w|
        if !e1.include?(w) 
          edit2.push(w) 
         end   
    }
    e2 = edit2
  end
  end
  total_freq = 0
  unless e1.nil?
    e1.each{|w|
      total_freq += NWORDS[w]
    }
  end
  unless e2.nil?
    e2.each{|w|
    total_freq += NWORDS[w]
  }
  end
  unless e1.nil?
    e1 = score(e1, word, total_freq)  
  end
  unless e2.nil?
    e2 = score(e2, word, total_freq)
  end
  puts "Top Five Words from ED1 & ED2 based on score \n"
  select_top_five(e1, e2,word) 
end

#Finds the top five suggestion from edit distance one and two,
#accoring to their scores.
def select_top_five(ed1,ed2,word)
  
  if(ed1 == nil)
    words = ed2 
  elsif(ed2 == nil)
    words = ed1
  else
    words = ed1.merge(ed2)
  end

  words = words.sort_by{|k,v| -v}.first 5
  words = Hash[*words.flatten]
  final_list = Hash.new{}

  if !NWORDS.has_key?(word)
      words.each_with_index { |(k,v),index|
        if index == (words.length-1)
          final_list[word] = v*0.5
        else
          final_list[k] = v
        end
      }
      words = final_list
  end 
  
  # words_only = Array.new()
  # words.each{ |k,v|
  #   words_only.push(k) 
  # }

  words.each { |k,v| 
    print (String(v)+" "+String(NWORDS[k])+"  "+k+"\n")
  }
  #puts words.class
  #return words_only  #list of words 
  return words       #Hash of words and corresponding score 
end

# Calculates the socre for each correction candidate
def score(words, word, total_freq)
  hash = Hash.new{}
  # total_freq = 0
  # words.each{|w|
  #   total_freq += NWORDS[w]
  # }
  
  words.each{|w|
    # if word == w
    #   s = 100
    # else 
    #   #s = (NWORDS[w]/(total_freq)*100).round(4)  
    #   s = (NWORDS[w]/(total_freq*words.length)*100).round(4)  
    #   #puts s
    # end
    s = (NWORDS[w]/(total_freq*words.length)*100).round(4)
    hash[w] = s   
  }
  hash = hash.sort_by{|k,v| -v}
  hash.each{|k,v| 
  #print (String(v)+" "+String(NWORDS[k])+"  "+k+"\n")
  } 
  hash = Hash[*hash.flatten]
  return hash
end

def sort_words_by_popularity(words,word)
  unless words.nil?
    #words.delete(word)
    sorted_words = words.sort_by{|w| -NWORDS[w] }
    array = sorted_words.first 10
    #print_words(array)
    return array
  end
end

def print_words words
  unless words.nil?
    words.each {|w| 
    print (NWORDS[w])
    print ("  "+w)
    puts
  }  
  end
  puts "\n\n"
end

correct("bonito")