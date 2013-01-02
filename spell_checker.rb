require 'mysql' 

def train features
  model = Hash.new(1)
  features.each_hash{|h| 
    model[h['name'].downcase] = Float(h['freq'])
    #puts Float(h['freq'])
  }

  return model
end

def database_connect
  con = Mysql.new('localhost', 'root', 'root', 'dob')
  rs = con.query('select * from name_freq')
  #rs.each_hash{|h| puts h['frequency']}
  con.close
  return rs
end 

NWORDS = train(database_connect)
LETTERS = ("a".."z").to_a.join

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

def known_edits2 word
  result = []
  edits1(word).each {|e1| edits1(e1).each {|e2| result << e2 if NWORDS.has_key?(e2) }}
  result.empty? ? nil : result
end

def known words
  result = words.find_all {|w| NWORDS.has_key?(w) }
  result.empty? ? nil : result
end

def correct word

  unless (edits1_candidate = (known(edits1(word)))).nil? 
    edits1_candidate = (known(edits1(word))).uniq
  end

  #edits2_candididate = (known_edits2(word)).uniq

  unless (edits2_candidate = (known_edits2(word))).nil? 
    edits2_candidate = (known_edits2(word)).uniq
  end

  if(word.length<= 3)
    edits2_candidate = nil
  end

  puts "Entered Word"
  puts word
  puts

  puts "Edit Distance 1"
  #print_words(edits1_candidate)
  edits1_candidate =sort_words_by_popularity(edits1_candidate,word)

  puts "Edit Distance 2"
  #print_words(edits2_candidate)
  edits2_candidate = sort_words_by_popularity(edits2_candidate,word)

  unless edits1_candidate.nil?
    edits1_candidate = score(edits1_candidate, edits1_candidate.length)  
  end

  unless edits2_candidate.nil?
    edits2_candidate = score(edits2_candidate, edits2_candidate.length)
  end

  puts "Top Five Words from ED1 & ED2 based on score \n"
  select_top_five(edits1_candidate, edits2_candidate) 

  #p NWORDS
end

#Finds the top five suggestion from edit distance one and two,
#accoring to their scores.
def select_top_five(ed1,ed2)
  unless ed2.nil?
    words = ed1.merge(ed2)  
  end
  words = ed1
  words.sort_by{|k,v| -v}
  words  = words.first 5 
  words.each { |k,v| 
    print (String(v)+" "+String(NWORDS[k])+"  "+k+"\n")

  }

end

# Calculates the socre for each correction candidate
def score(words, len)
  
  hash = Hash.new{}
  total_freq = 0
  words.each{|w|
    total_freq += NWORDS[w]
  }

  words.each{|w|
    s = NWORDS[w]/(total_freq*len)*100
    hash[w] = s   
  }

  hash.sort_by{|k,v| -v}
  return hash

end

def sort_words_by_popularity(words,word)
  unless words.nil?
    words.delete(word)
    sorted_words = words.sort_by{|w| -NWORDS[w] }
    len = sorted_words
    array = sorted_words.first 10
    print_words(array)
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

correct('ana')
