require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(number)
  if number.length < 10 || number.length > 10 && number[0] != 1
    'bad number'
  else
    number
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

popular_hours = {}
popular_days = {}

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  phone_number = clean_phone_number(row[:homephone])

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  date_time = row[:regdate].split(' ')

  puts date_time[0]
  date = Date.strptime(date_time[0], '%m/%d/%y')
  time = Time.parse(date_time[1])

  day = date.wday
  hour = time.hour

  popular_days[day] = popular_days[day].nil? ? 1 : popular_days[day] + 1
  popular_hours[hour] = popular_hours[hour].nil? ? 1 : popular_hours[hour] + 1

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

puts popular_hours.sort_by(&:last).reverse.to_h
puts popular_days.sort_by(&:last).reverse.to_h

# lines = File.readlines('event_attendees.csv')
# lines.each_with_index do |line, index|
#   next if index == 0

#   columns = line.split(',')
#   name = columns[2]
#   puts name
# end
