#!/bin/ruby

require 'find'
require 'json'
require 'octokit'
require 'fileutils'
require 'erb'
require 'yaml'
require 'digest'

## Page module stores data for pages.
module Page
 attr_reader :title, :source, :target, :content, :date, :tags
 attr_reader :public_html, :markdown_src, :template_src

 ## Initialize a new page
 def initialize(data = {})

  # Initialize the fs locations
  @template_src = "src/templates"
  @public_html = "public_html"
  @markdown_src = "src/markdown/#{self.class}"
  @markdown_src = "src/markdown" if self.class == RootPage

  # Initialize the metadata
  @title  = data["title"]
  @source = data["source"]
  @date   = data["date"]
  @target = data["target"]
  @tags   = data["tags"]

  @date ||= Time.now
  @source ||= title2source
  @target ||= source2target
  @tags   ||= []

  # Generate the content
  @content = md2html @source
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
 def title2source
  source = @title.gsub /\ /, '_'
  "#{@markdown_src}/#{source}.md"
 end

 ## Determine the target path for the page
 def source2target
  out_file = File.basename(@source).sub /\.md$/, ".html"
  "#{@public_html}/#{self.class}/#{out_file}"
  "#{@public_html}/#{out_file}" if self.class == RootPage
 end

 ## Convert the file to markdown
 def md2html(in_file)
  return "" unless File.exists?(in_file)
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
   File.dirname(@target).sub(/^#{@public_html}/, '') + "/"
  else
   @target.sub /^#{@public_html}/, ''
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
  pre_template  = ERB.new(File.read("#{@template_src}/pre.html.erb"), 0, '-')
  main_template = ERB.new(File.read("#{@template_src}/main.html.erb"), 0, '-')
  post_template = ERB.new(File.read("#{@template_src}/post.html.erb"), 0, '-')
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
 include Page
 include Enumerable
 
 def self.meta_data_file
  "data/#{self}.yaml"
 end

 def self.each(&block)
  self.load.each(&block)
 end

 def self.render
  self.each { |p| p.render }
 end

 ## Load all the pages
 def self.load
  pages = []
  data = YAML::load_file self.meta_data_file
  data.each { |page| pages << new(page) } 
  pages
 end

 ## Save pages
 def self.save(pages)
  data = []
  pages.each { |page| data << page.dump }
  File.write self.meta_data_file, YAML::dump(data)
 end

 ## Add a new page
 def self.add(data)
  pages = self.load
  pages << new(data)
  self.save pages
  pages.last
 end

 ## Delete pages
 def self.delete(pattern)
  rm_data = self.search(pattern).map(&:dump)
  pages = []
  self.each { |page| pages << page unless rm_data.include?(page.dump) }
  self.save pages
  rm_data.count
 end

 ## Sort pages
 def self.sort(&block)
  self.each.sort(&block)
 end

 ## Search for a page
 def self.search(dict)
  matches = []
  self.each { |page| matches << page if dict < page.dump }
  matches
 end
end

## Root class stores data for the root pages.
class RootPage
 include Page
end

## Article class stores data for the articles.
class Article
 include Page
end

## Roots class lets you access all the root pages
class RootPages < Pages
end

## Articles class lets you access all the articles
class Articles < Pages
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
 def self.write(cache)
  FileUtils::mkdir_p File.dirname(@cache_file)
  File.write @cache_file, YAML::dump(cache)
 end
end

class Site
 def self.init_public_html
  ## Clear the existing public_html directory
  FileUtils::rm_rf "public_html"
  FileUtils::mkdir_p "public_html"
  
  ## Symlink the needful
  FileUtils::symlink "../assets", "public_html"
 end

 def self.render
  ## Initialize the site
  self.init_public_html

  ## Print each page that is loaded
  RootPages.each { |p| puts p }
  Articles.each { |p| puts p }
  
  ## Generate each page
  RootPages.render
  Articles.render
 end
end

class Menu
 ## Print menu usage
 def self.usage
  puts "Usage:"
  puts " #{$0} render"
  puts " #{$0} new rootpage|article TITLE [SOURCE]"
  puts " #{$0} rm rootpage|article TITLE [SOURCE]"
 end

 ## Check args
 def self.check_args
  unless ARGV[2]
   Menu.usage
   exit 1
  end
  return { "title" => ARGV[2], "source" => ARGV[3] } if ARGV[3]
  { "title" => ARGV[2] }
 end

 ## Create something new
 def self.new
  data = self.check_args
  case ARGV[1]
   when 'article'
    page = Articles.add data
    puts "New article #{ARGV[2]} created."
    puts "Source: #{page.source}"
   when 'page'
    page = RootPages.add data
    puts "New page #{ARGV[2]} created."
    puts "Source: #{page.source}"
   else
    Menu.usage
    exit 1
  end
 end

 ## Remove something
 def self.rm
  data = self.check_args
  case ARGV[1]
   when 'article'
    n = Articles.delete data
    puts "#{n} article metadata deleted; sources untouched."
   when 'rootpage'
    page = RootPages.delete data
    puts "#{n} page metadata deleted; sources untouched."
  end
 end

 ## Render the site
 def self.render
  Site.render
 end
end

if ARGV[0] =~ /new|rm|render/
 Menu.send(ARGV[0])
else
 Menu.usage
end
