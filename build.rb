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

 ## Convert the file name into the title
 def source2title(in_file)
  title = File.basename in_file
  title = title.sub /.md$/, '' # Remove the extension
  title = title.sub /#.*/, ''  # Remove the tags
  title.gsub /_/, ' '          # Convert underscore to spaces
 end

 ## Convert the file name into tags
 def source2tags(in_file)
  tags = File.basename in_file
  tags = tags.sub /.md$/, '' # Remove the extension
  tags = tags.split '#'      # Separate the tags
  tags.drop 1                # Drop the title
 end

 ## Determine the target path for the page
 def source2target(in_file, section)
  out_file = File.basename(in_file).sub /.md$/, ".html"
  if section != nil
   "#{$public_html}/#{section}/#{out_file}"
  else
   "#{$public_html}/#{out_file}"
  end
 end

 ## Determine what section the page belongs to
 def source2section(in_file)
  section = File.dirname(in_file).sub /^#{$markdown_src}/, ''
  section.split('/')[1]
 end

 ## Determine the publish date for the page
 def source2date(in_file, section)
  ## The sub directories should indicate the date
  if section and File.dirname(in_file) != "#{$markdown_src}/#{section}"
   date = File.dirname(in_file).sub /^#{$markdown_src}\/#{section}\//, ''
   date = date.split('/')
   Time.new date[0], date[1], date[2]
  ## Otherwise, just use the modification time
  else
   File.mtime in_file
  end
 end

 ## Convert the file to markdown
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

 ## Reload the page's content
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

 ## String representation of the page
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
  FileUtils::mkdir_p File.dirname @target
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

 ## Generate all pages
 def self.read_all
  ## Load the data for the pages
  Find.find($markdown_src) do |in_file|
   ## Only operate on files
   next unless File.file? in_file
   ## Only operate on markdown
   next unless in_file =~ /.md$/
   Page.new in_file
  end
 end

 ## Render all pages
 def self.render_all
  @@instance_collector.each { |p| p.render }
 end
end

class Cache
 ## Read the cache file
 def self.read(cache_file)
  return {} unless File.exists? cache_file
  YAML::load_file cache_file
 end

 ## Save the cache file
 def self.write(cache_file, cache)
  FileUtils::mkdir_p File.dirname(cache_file)
  File.write cache_file, YAML::dump(cache)
 end
end

class Site
 def self.init_public_html
  ## Clear the existing public_html directory
  FileUtils::rm_rf $public_html
  FileUtils::mkdir_p $public_html
  
  ## Symlink the needful
  FileUtils::symlink "../assets", $public_html
  FileUtils::symlink "../bower_components", $public_html
 end

 def self.render
  ## Initialize the site
  Site.init_public_html

  ## Load the cache
  $cache = Cache.read $cache_file

  ## Load the data for the pages
  Page.read_all
  
  ## Generare each page
  Page.render_all

  ## Save the cache
  Cache.write $cache_file, $cache
 end
end

Site.render
