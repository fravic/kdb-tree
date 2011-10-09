#!/usr/bin/env ruby

# Generates a randomized payments file for testing
# Usage: ./gen_payments.rb 1000000 payments.txt

NAME_WORDS = ['Chairman', 'Bao',
              'Sightglass', 'Coffee',
              'Creme', 'Brulee', 'Cart',
              'Everyman', 'Espresso',
              'Motek',
              'Butter', 'Lane',
              'Hello', 'Bicycle',
              'Humble', 'House', 'Foods',
              'Fravic', 'Square', 'Employee',
              'Golden', 'Gate', 'Bridge']

CATEGORIES = ['food-truck',
              'bank',
              'coffee-shop',
              'startup',
              'vehicles',
              'mall',
              'restaurant',
              'tea-stand']

# Set lat and lng range to San Francisco
LAT_RANGE = (37.70339999999999..37.8120)
LNG_RANGE = (-122.5270..-122.34820)

if ARGV.size < 2
  p "Usage: ./gen_payments.rb num_rows filename"
  exit(0)
end

r = Random.new
num_rows = ARGV[0].to_i
filename = ARGV[1]

out = File.open(filename, 'w')
(1..num_rows).each do |i|
  first_name = NAME_WORDS[r.rand(NAME_WORDS.size)]
  last_name = NAME_WORDS[r.rand(NAME_WORDS.size)]
  name = first_name + ' ' + last_name + ' (#' + i.to_s + ')'
  category = CATEGORIES[r.rand(CATEGORIES.size)]
  entry = [name, category, r.rand(LAT_RANGE), r.rand(LNG_RANGE)]
  out.puts(entry.join(', '))
end
