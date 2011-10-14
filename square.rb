#!/usr/bin/env ruby

# square.rb
#
# Runs a set of queries on a list of payments.  Formats input for insertion into
# a KDBTree and runs queries from the given text file.
#
# Usage:
# ./square.rb payments.txt queries.txt
#
# Written by Fravic (fravic.com) for the Square coding challenge.

require './kdbtree.rb'
include KDBTree

KM_PER_DEGREE = 111

if ARGV.size < 2
  puts "Usage: ./square payments_filename queries_filename"
  exit(0)
end

tree = Tree.new(Region.new([(-90...90), (-180...180)]))

# Read payments file
# eg. Chairman Bao, food-truck,  37.762605, -122.434767
payfile = File.open(ARGV[0], 'r')
payfile.each_line do |line|
  payment = line.split(',')
  name = payment[0].strip
  category = payment[1].strip
  lat = payment[2].to_f
  lng = payment[3].to_f
  coords = [lat, lng]
  data = {:name => name, :category => category}
  tree.insert(coords, data, category)
  print "Initializing payments tree.  Adding payment #{payfile.lineno}...\r"
end

# Run queries from file
# eg. 37.762605, -122.409849, food-truck, 2.0
queryfile = File.open(ARGV[1], 'r')
queryfile.each_line do |line|
  query = line.split(',')
  lat = query[0].to_f
  lng = query[1].to_f

  # By default, use no category
  category = nil
  category = query[2].strip if query.size >= 3 && !query[2].strip.empty?

  # By default, use a 1km radius
  # In reality, KM_PER_DEGREE will vary across the globe.  Use this as a
  # reasonable approximation.
  dist = 1.0 / KM_PER_DEGREE
  dist = query[3].to_f / KM_PER_DEGREE if query.size >= 4

  lat_range = (lat - dist...lat + dist)
  lng_range = (lng - dist...lng + dist)
  region = Region.new([lat_range, lng_range])

  results = tree.query(region, category)

  # KDBTree returns points from a rectangular region; need a circular radius
  results.reject! do |r|
    Math.sqrt((r[:coords][0] - lat) ** 2 + (r[:coords][1] - lng) ** 2) > dist
  end

  results.each do |r|
    entry = [r[:data][:name],
             r[:data][:category],
             r[:coords][0],
             r[:coords][1]]
    puts entry.join(', ')
  end

  # Empty line between queries
  puts
end
