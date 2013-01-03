
require "./spell_checker"
require 'csv'


#Replace the test typos below
test_case = ['Haelen','Haabel','Marrk','Maccy','Hlen','Egenia','acy',
	'Dcire','Hleen','Mable','Dicei','Hilin','Mabal','Maoy','Dlcie',
	'Dark','Rogert','Decei','roth','rosa','evan','jelma','alv', 'rose']

# test_case = ['Haelen','Haabel']

#Typo and most five probable correction list are written in csv file.


CSV.open('output1.csv', 'w') do |csv|
  
  test_case.each{|word|
  	list = Array.new()
  	list.push(word)
  	correction_list = [correct(word)]
  	list = list.concat(correction_list)
  	csv << list
  }
end

# test_case.each{|word|
#   	list = Array.new()
#   	list.push(word)
#   	correction_list = correct(word)
#   	list = list.concat(correction_list)
#   	puts list
#     }