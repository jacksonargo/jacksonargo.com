#!/bin/ruby

require 'find'
require 'json'
require 'octokit'

File.open("pre.html") do |f|
 @pre_html = f.read
end

File.open("post.html") do |f|
 @post_html = f.read
end

## Find all the markdown files

Find.find(".") do |in_file|
 ## Only operate on files
 next unless File.file? in_file
 ## Only operate on markdown
 next unless in_file =~ /.md$/

 ## Rename the output file to .html
 out_file = in_file.sub /.md$/, ".html"

 ## Convert markdown to html
 File.open in_file do |f|
  @in_html = Octokit.markdown f.read, :mode => "gfm"
 end

 ## Write our output file
 File.open out_file, "w" do |f|
  f.write @pre_html + @in_html + @post_html
 end
end
