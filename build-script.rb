#!/bin/ruby

require 'find'
require 'json'
require 'octokit'
require 'fileutils'
require 'erb'

public_html = "public_html"

## Load the pre and post templates

pre_template = ERB.new File.read("src/templates/pre.html.erb"), 0, '-'
@pre_html = pre_template.result
post_template = ERB.new File.read("src/templates/post.html.erb"), 0, '-'
@post_html = post_template.result

## Cleat the existing public_html directory

FileUtils::rm_rf public_html
FileUtils::mkdir_p public_html

## Symlink the needful

FileUtils::symlink "../assets", public_html
FileUtils::symlink "../bower_components", public_html

## Make the sub directories

Find.find("src/markdown") do |src_dir|
 ## We only care about directories
 next unless File.directory? src_dir

 # Convert the path name
 target_dir = src_dir.sub /^src\/(markdown|assets)/, public_html

 # Create the directory
 FileUtils::mkdir_p target_dir
end

## Convert everything in src/markdown

Find.find("src/markdown") do |in_file|
 ## Only operate on files
 next unless File.file? in_file
 ## Only operate on markdown
 next unless in_file =~ /.md$/

 ## Rename the output file to .html
 out_file = in_file.sub /.md$/, ".html"
 out_file = out_file.sub /^src\/markdown/, public_html

 ## Convert markdown to html
 File.open in_file do |f|
  @in_html = Octokit.markdown f.read, :mode => "gfm"
 end

 ## Write our output file
 File.open out_file, "w" do |f|
  f.write @pre_html + @in_html + @post_html
 end
end
