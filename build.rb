#!/bin/ruby

require 'find'
require 'json'
require 'octokit'
require 'fileutils'
require 'erb'
require 'yaml'
require 'digest'

$public_html = "public_html"
$markdown_src = "src/markdown"
$template_src = "src/templates"
$cache_file = "cache/pages.yaml"

## Page class stores data for each markdown file.
class Page
 attr_reader :title, :source, :target, :content, :date, :section

 @@instance_collector = []

 ## Initialize the class
 def initialize(in_file)
  @source = in_file
  @title = source2title in_file
  @tags = source2tags in_file
  @section = source2section in_file
  @content = md2html in_file
  @date = source2date in_file, @section
  @target = source2target in_file, @section
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

 def source2target(in_file, section)
  out_file = File.basename(in_file).sub /.md$/, ".html"
  "#{$public_html}/#{section}/#{out_file}"
 end

 def source2section(in_file)
  section = File.dirname(in_file).sub /^#{$markdown_src}/, ''
  section.split('/')[1]
 end

 def source2date(in_file, section)
  if section and File.dirname(in_file) != "#{$markdown_src}/#{section}"
   date = File.dirname(in_file).sub /^#{$markdown_src}\/#{section}\//, ''
   date = date.split('/')
   Time.new date[0], date[1], date[2]
  else
   File.mtime in_file
  end
 end

 def md2html(in_file)
  ## Only regenerate if what is in cache doesn't match
  md5_in = Digest::MD5.hexdigest File.read(in_file)
  if $cache[in_file] != nil
   md5_cache = $cache[in_file]["md5sum"]
   return $cache[in_file]["content"] if md5_in == md5_cache
  end

  ## If there is an access token in the environment, we can use that to auth
  token = ENV['TOKEN']
  if token != nil
   client = Octokit::Client.new :access_token => token
   content = client.markdown File.read(in_file), :mode => "gfm"
  else
   content = Octokit.markdown File.read(in_file), :mode => "gfm"
  end

  ## Update the cache
  $cache[in_file] = { "md5sum" => md5_in, "content" => content }

  ## We are done
  return content
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
  sections.each_key { |k| array << k if k }
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
 
 ## Load/initialize the cache
 if File.exists? $cache_file
  $cache = YAML::load_file $cache_file
 else
  FileUtils::mkdir_p File.dirname($cache_file)
  $cache = {}
 end

 ## Load the data for the pages
 Find.find("src/markdown") do |in_file|
  ## Only operate on files
  next unless File.file? in_file
  ## Only operate on markdown
  next unless in_file =~ /.md$/
  Page.new in_file
 end
 
 ## Make the sub directories
 Find.find($markdown_src) do |src_dir|
  ## We only care about directories
  next unless File.directory? src_dir
  # Convert the path name
  target_dir = src_dir.sub /^#{$markdown_src}/, $public_html
  # Create the directory
  FileUtils::mkdir_p target_dir
 end
 
 ## Generare each page
 Page.all_pages.each { |page| page.render }
 
 ## Save the cache file
 File.open($cache_file, "w") { |f| f.write YAML::dump($cache) }
end

render_site
