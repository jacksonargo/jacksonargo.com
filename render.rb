#!/bin/ruby

require 'find'
require 'json'
require 'octokit'
require 'fileutils'
require 'erb'
require 'yaml'
require 'digest'

$template_src = "src/templates"
$markdown_src = "src/markdown"
$metadata_src = "data/metadata.yaml"
$public_html = "public_html"

## Class to render the individual pages
class Page
 attr_reader :title, :source, :target, :content, :date, :tags

 ## Initialize a new page
 def initialize(source)

  @source = source

  # Initialize the metadata
  data = source2meta
  if data
    @title  = data["title"]
    @date   = data["date"]
    @target = data["target"]
    @tags   = data["tags"]
  end

  @date   ||= Time.now
  @title  ||= source2title
  @target ||= source2target
  @tags   ||= []

  savemeta

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

 ## Returns metadata for file
 def source2meta
  return nil unless File.exists? $metadata_src
  data = YAML::load_file $metadata_src
  data.select{ |k| k["source"] == @source }.first
 end

 ## Convert the source name into the title
 def source2title
  title = File.basename @source
  title = title.sub /\.md$/, ''
  title.gsub /_/, ' '
 end

 ## Determine the target path for the page
 def source2target
  out_file = @source.sub /\.md$/, ".html"
  out_file.sub $markdown_src, $public_html
 end

 ## Save metadata
 def savemeta
  if File.exists? $metadata_src
   data = YAML::load_file $metadata_src
   data.delete(source2meta)
  end
  data ||= []
  data << dump
  File.write $metadata_src, YAML::dump(data)
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

 ## Check if the page is an article
 def is_article?
  @source =~ /^#{$markdown_src}\/Articles/
 end

 ## Return a link to the page.
 def link
  if is_index?
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

## My resume is a special beast who's markdown is templated
## I also have a latex version that has to be rendered
class Resume
 def self.render_md
  @resume = YAML::load_file "data/resume.yaml"
  template = ERB.new(File.read("src/templates/Resume.md.erb"), 0, '-')
  md = template.result binding
  File.write "src/markdown/Resume.md", md
 end
 def self.render_tex
  @resume = YAML::load_file "data/resume.yaml"
  template = ERB.new(File.read("src/templates/Resume.tex.erb"), 0, '-')
  tex = template.result binding
  File.write "src/latex/Resume.tex", tex
 end
 def self.render
  self.render_md
  self.render_tex
 end
end

## Class to render all the pages
class Site
 def self.init
  ## Clear the existing public_html directory
  FileUtils::rm_rf $public_html
  FileUtils::mkdir_p $public_html
  
  ## Symlink the needful
  FileUtils::symlink "../assets", $public_html
 end

 def self.render
  # Initialize the site
  self.init
  # Prerender Resume
  Resume.render
  # Preload each page
  $pages = []
  Find.find("src/markdown").each do |page|
   $pages << Page.new(page) if page =~ /\.md$/
  end
  # Render each page
  $pages.each do |p|
   p.render
   puts "Rendered #{p.title}"
  end
 end
end

Site.render
