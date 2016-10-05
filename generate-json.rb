#!/bin/ruby

require 'json'

infile = File.open(ARGV[0], "r")
outfile = File.open(ARGV[0] + ".json", "w")

d = {}
d[:text] = infile.read
d[:mode] = "gfm"

outfile.write d.to_json

infile.close
outfile.close
