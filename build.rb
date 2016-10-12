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
$cache_file = "cache/cache.yaml"

## Page class stores data for pages.
class Page
 attr_reader :title, :source, :target, :content, :date, :tags

 ## Initialize a new page
 def initialize(data = {})
  @title  = data["title"]
  @source = data["source"]
  @date   = data["date"]
  @target = data["target"]
  @tags   = data["tags"]
  @content = md2html data["source"]

  @date ||= Time.now
  @source ||= title2source @title
  @target ||= source2target @source
  @tags   ||= []
 end

 ## Dump the page meta data as a hash
 def dump
  {
    "source" => @source,
    "title"  => @title,
    "date"   => @date,
    "target" => @target,
    "tags"   => @tags
  }
 end

 ## Convert the title into the source name
 def title2source(t)
  s = t.gsub /\ /, '_'
  "#{s}.md"
 end

 ## Determine the target path for the page
 def source2target(s)
  out_file = File.basename(s).sub /\.md$/, ".html"
  "#{$public_html}/#{out_file}"
 end

 ## Convert the file to markdown
 def md2html(in_file)
  ## Only regenerate if what is in cache doesn't match
  md5_in = Digest::MD5.hexdigest File.read(in_file)
  return Cache.content(in_file) if md5_in == Cache.md5sum(in_file)

  ## If there is an access token in the environment, we can use that to auth
  token = ENV['TOKEN']
  if token != nil
   client = Octokit::Client.new :access_token => token
   content = client.markdown File.read(in_file), :mode => "gfm"
  else
   content = Octokit.markdown File.read(in_file), :mode => "gfm"
  end

  ## Update the cache
  Cache.update in_file, { "md5sum" => md5_in, "content" => content }

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
end

## Pages class lets you access all the pages.
class Pages
 include Enumerable
 
 @meta_data_file = "data/pages.yaml"

 def self.each(&block)
  self.load.each(&block)
 end

 def self.render
  self.each { |p| p.render }
 end

 ## Load all the pages
 def self.load
  pages = []
  data = YAML::load_file @meta_data_file
  data.each { |page| pages << Page.new(page) } 
  pages
 end

 ## Save all the pages
 def self.add(new)
  data = []
  self.each do |page|
   data << page.dump
  end
  data << new
  File.write @meta_data_file, YAML::dump(data)
 end
end

## Article class stores data for the articles.
class Article < Page
 ## Determine the target path for the page
 def source2target(in_file, section)
  out_file = File.basename(in_file).sub /.md$/, ".html"
  "#{$public_html}/Articles/#{out_file}"
 end
end

## Articles class lets you access all the articles
class Articles < Pages
 @meta_data_file = "data/articles.yaml"
end

## Class to access the cache
class Cache

 @cache_file = "cache/cache.yaml"

 ## Update the cache
 def self.update(in_file, data = {})
  cache = self.read
  cache[in_file] = data
  self.write cache
 end

 ## Purge the cache
 def self.purge
  self.write {}
 end

 ## Access md5sum
 def self.md5sum(in_file)
  cache = self.read
  cache[in_file] ||= {}
  cache[in_file]["md5sum"]
 end

 ## Access content
 def self.content(in_file)
  cache = self.read
  cache[in_file] ||= {}
  cache[in_file]["content"]
 end

 ## Read the cache file
 def self.read
  return {} unless File.exists? @cache_file
  YAML::load_file @cache_file
 end

 ## Save the cache file
 def write(cache)
  FileUtils::mkdir_p File.dirname(@cache_file)
  File.write @cache_file, YAML::dump(cache)
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

  ## Load the data for the pages
  Pages.each { |p| puts p }
  Articles.each { |p| puts p }
  
  ## Generare each page
  Pages.render
  Articles.render
 end
end

case ARGV[0]
 when 'new'
  case ARGV[1]
   when 'article'
    Article.new ARGV[2]
   when 'page'
    Page.new ARGV[2]
  end
 when 'render'
  Site.render
end
