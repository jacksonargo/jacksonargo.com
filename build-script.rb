#!/bin/ruby

require 'find'
require 'json'
require 'octokit'
require 'fileutils'

File.open("src/templates/pre.html") do |f|
 @pre_html = f.read
end

File.open("src/templates/post.html") do |f|
 @post_html = f.read
end

## Make the public_html directories and copy the assets

Find.find("src/markdown", "src/assets") do |src_dir|
 ## We only care about directories
 next unless File.directory? src_dir

 # Convert the path name
 target_dir = src_dir.sub /^src\/(markdown|assets)/, "public_html"

 # Create the directory
 FileUtils::mkdir_p target_dir
end

## Copy the assets to public_html

Find.find("src/assets") do |asset|
 ## We only care about files
 next unless File.file? asset
 target = asset.sub /^src\/assets/, "public_html"
 FileUtils.cp asset, target
end

## Convert everything in src/markdown

Find.find("src/markdown") do |in_file|
 ## Only operate on files
 next unless File.file? in_file
 ## Only operate on markdown
 next unless in_file =~ /.md$/

 ## Rename the output file to .html
 out_file = in_file.sub /.md$/, ".html"
 out_file = out_file.sub /^src\/markdown/, "public_html"

 ## Convert markdown to html
 File.open in_file do |f|
  @in_html = Octokit.markdown f.read, :mode => "gfm"
 end

 ## Write our output file
 File.open out_file, "w" do |f|
  f.write @pre_html + @in_html + @post_html
 end
end
