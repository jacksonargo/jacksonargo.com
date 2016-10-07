#!/bin/ruby

require 'find'
require 'json'
require 'octokit'
require 'fileutils'
require 'erb'

$public_html = "public_html"
$mardown_src = "src/markdown"
$template_src = "src/templates"

## Page class stores data for each markdown file.
class Page
 attr_reader :title, :source, :target, :content, :date, :section

 @@instance_collector = []

 ## Initialize the class
 def initialize(in_file)
  @source = in_file
  @title = source2title in_file
  @tags = source2tags in_file
  @target = source2target in_file
  @content = md2html in_file
  @date = File.mtime in_file
  @section = source2section in_file
  @@instance_collector << self
 end

 def source2title(in_file)
  title = File.basename in_file
  title = title.sub /.md$/, '' # Remove the extension
  title = title.sub /#.*/, ''  # Remove the tags
  title.gsub /_/, ' '          # Convert underscore to spaces
 end

 def source2tags(in_file)
  tags = File.basename in_file
  tags = tags.sub /.md$/, '' # Remove the extension
  tags = tags.split '#'      # Separate the tags
  tags.drop 1                # Drop the title
 end

 def source2target(in_file)
  out_file = in_file.sub /.md$/, ".html"
  out_file.sub /^#{$mardown_src}/, $public_html
 end

 def source2section(in_file)
  section = File.dirname(in_file).sub /^#{$mardown_src}/, ''
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

 def refresh_content
  @content = md2html @source
 end

 ## Check if this page is an index
 def is_index?
  @source =~ /\/index.md$/
 end

 ## Return a link to the page.
 def link
  if @title == "index"
   File.dirname(@target).sub(/^#{$public_html}/, '') + "/"
  else
   @target.sub /^#{$public_html}/, ''
  end
 end

 def to_s
  @title
 end

 ## Write the full html page
 def render
  b = binding
  ## Load the templates
  pre_template  = ERB.new(File.read("#{$template_src}/pre.html.erb"), 0, '-')
  main_template = ERB.new(File.read("#{$template_src}/main.html.erb"), 0, '-')
  post_template = ERB.new(File.read("#{$template_src}/post.html.erb"), 0, '-')
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
  sections.each_key { |k| array << k if k != '' }
  array
 end

 ## Return all the pages that are part of a section
 def self.section(section)
  p = []
  @@instance_collector.each do |x|
   next if x.is_index?
   p << x if x.section == section
  end
  return p
 end

 ## Find the page with the matching title
 def self.with_title(title)
  @@instance_collector.each do |x|
   return x if x.title == title
  end
  return nil
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
 end
 
 ## Make the sub directories
 Find.find($mardown_src) do |src_dir|
  ## We only care about directories
  next unless File.directory? src_dir
  # Convert the path name
  target_dir = src_dir.sub /^#{$mardown_src}/, $public_html
  # Create the directory
  FileUtils::mkdir_p target_dir
 end
 
 ## Generare each page
 Page.all_pages.each { |page| page.render }
end

render_site
