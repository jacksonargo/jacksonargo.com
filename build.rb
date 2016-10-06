#!/bin/ruby

require 'find'
require 'json'
require 'octokit'
require 'fileutils'
require 'erb'

$public_html = "public_html"

## Page class stores data for each markdown file.
class Page
 attr_reader :title, :source, :target, :content, :date, :section

 @@instance_collector = []

 ## Initialize the class
 def initialize(in_file)
  @source = in_file
  @title = source2title in_file
  @target = source2target in_file
  @content = md2html in_file
  @date = File.mtime in_file
  @section = source2section in_file
  @@instance_collector << self
  puts "Loaded new page #{@title}"
 end

 def source2title(in_file)
  title = File.basename in_file
  title = title.sub /.md$/, ''
  title.gsub /_/, ' '
 end

 def source2target(in_file)
  out_file = in_file.sub /.md$/, ".html"
  out_file.sub /^src\/markdown/, $public_html
 end

 def source2section(in_file)
  section = File.dirname(in_file).sub /^src\/markdown/, ''
  section.sub /^\//, ''
 end

 def md2html(in_file)
  ## If there is an access token in the environment, we can use that to auth
  token = ENV['TOKEN']
  if token != nil
   client = Octokit::Client.new :access_token => token
   client.markdown File.read(in_file), :mode => "gfm"
  else
   Octokit.markdown File.read(in_file), :mode => "gfm"
  end
 end

 ## Check if this page is an index
 def is_index?
  @source =~ /\/index.md$/
 end

 ## Return a link to the page.
 def link
  @target.sub /^#{$public_html}/, ''
 end

 def to_s
  @title
 end

 ## Write the full html page
 def render
  b = binding
  ## Load the templates
  pre_template  = ERB.new(File.read("src/templates/pre.html.erb"), 0, '-')
  main_template = ERB.new(File.read("src/templates/main.html.erb"), 0, '-')
  post_template = ERB.new(File.read("src/templates/post.html.erb"), 0, '-')
  ## Generate the html page
  pre = pre_template.result b
  post = post_template.result b
  main = main_template.result b
  File.open(@target, "w") { |f| f.write pre + main + post }
 end

 ## Return array of each page
 def self.all_pages
  @@instance_collector
 end

 ## Return all sections as array
 def self.all_sections
  sections = {}
  @@instance_collector.each do |page|
   sections[page.section] = true
  end
  array = []
  sections.each_key { |k| a << k }
  array
 end

 ## Return all the pages that are part of a section
 def self.section(section)
  p = []
  @@instance_collector.each { |x| p << x if x.section == section }
  return p
 end
end

def render_site
 ## Clear the existing public_html directory
 FileUtils::rm_rf $public_html
 FileUtils::mkdir_p $public_html
 
 ## Symlink the needful
 FileUtils::symlink "../assets", $public_html
 FileUtils::symlink "../bower_components", $public_html
 
 ## Load the data for the pages
 Find.find("src/markdown") do |in_file|
  ## Only operate on files
  next unless File.file? in_file
  ## Only operate on markdown
  next unless in_file =~ /.md$/
  Page.new in_file
  puts "Current pages:"
  Page.all_pages.each { |page| puts " - #{page}" }
 end
 
 ## Make the sub directories
 Find.find("src/markdown") do |src_dir|
  ## We only care about directories
  next unless File.directory? src_dir
  # Convert the path name
  target_dir = src_dir.sub /^src\/(markdown|assets)/, $public_html
  # Create the directory
  FileUtils::mkdir_p target_dir
 end
 
 ## Generare each page
 Page.all_pages.each { |page| page.render }
end

render_site
