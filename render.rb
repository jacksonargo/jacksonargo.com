#!/bin/ruby

require 'find'
require 'json'
require 'octokit'
require 'fileutils'
require 'erb'
require 'yaml'
require 'digest'

## Global vars

$template_src = 'src/templates'
$markdown_src = 'src/markdown'
$html_src     = 'src/html'
$tex_src      = 'src/latex'
$public_html  = 'public_html'

## Class to render the individual pages
## The page title and url will be determined be the name of the source file
## The date and tags will be deteremined by existing metadata

class Page
  attr_reader :title, :source, :target, :content, :date, :tags

  ## Initialize a new page
  def initialize(source)
    @source = source

    # Initialize the metadata
    data = Metadata.for(@source)
    if data
      @title  = data['title']
      @date   = data['date']
      @target = data['target']
      @tags   = data['tags']
    end

    @date   ||= Time.now
    @title  ||= source2title
    @target ||= source2target
    @tags   ||= []

    Metadata.update(@source, dump)

    # Generate the content
    refresh_content
  end

  ## Dump the page meta data as a hash
  def dump
    {
      'source' => @source,
      'title'  => @title,
      'date'   => @date,
      'target' => @target,
      'tags'   => @tags
    }
  end

  ## Convert the source name into the title
  def source2title
    title = File.basename @source
    title = title.sub(/\.md$/, '') if is_md?
    title = title.sub(/\.html$/, '') if is_html?
    title.tr('_', ' ')
  end

  ## Determine the target path for the page
  def source2target
    out_file = @source.sub(/\.md$/, '.html') if is_md?
    out_file = @source if is_html?
    out_file.sub $markdown_src, $public_html if is_md?
    out_file.sub $html_src, $public_html if is_html?
  end

  ## Reload the page's content
  def refresh_content
    @content = md2html if is_md?
    @content = html2html if is_html?
  end

  ## Reads in html and returns it as string
  def html2html
    File.read @source
  end

  ## Convert the file to markdown via Octokit
  def md2html
    in_file = @source
    return '' unless File.exist?(in_file)
    ## Only regenerate if what is in cache doesn't match
    md5_in = Digest::MD5.hexdigest File.read(in_file)
    return Cache.content(in_file) if md5_in == Cache.md5sum(in_file)

    ## If there is an access token in the environment, we can use that to auth
    token = ENV['TOKEN']
    if !token.nil?
      client = Octokit::Client.new access_token: token
      # Use gfm mode to get extra github style formatting
      content = client.markdown File.read(in_file), mode: 'gfm'
    else
      content = Octokit.markdown File.read(in_file), mode: 'gfm'
    end

    ## Update the cache
    Cache.update in_file, 'md5sum' => md5_in, 'content' => content

    ## We are done
    content
  end

  ## Check if this page is an index
  def is_index?
    @target =~ /\/index.html$/
  end

  ## Check if the page is an article
  ## Used when generating the menu bar
  def is_article?
    @target =~ /^#{$public_html}\/Articles/
  end

  ## Check if a page source is markdown
  def is_md?
    @source =~ /\.md$/
  end

  ## Check if a page source is html
  def is_html?
    @source =~ /\.html$/
  end

  ## Return a link to the page.
  def link
    if is_index?
      File.dirname(@target).sub(/^#{$public_html}/, '') + '/'
    else
      @target.sub(/^#{$public_html}/, '')
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
    FileUtils.mkdir_p File.dirname @target
    File.open(@target, 'w') { |f| f.write pre + main + post }
  end
end

## Class to access the cache
## This keeps me from hitting my api limit while testing

class Cache
  @cache_file = 'cache/cache.yaml'

  ## Update the cache
  def self.update(in_file, data = {})
    cache = read
    cache[in_file] = data
    write cache
  end

  ## Purge the cache
  def self.purge
    write {}
  end

  ## Access md5sum
  def self.md5sum(in_file)
    cache = read
    cache[in_file] ||= {}
    cache[in_file]['md5sum']
  end

  ## Access content
  def self.content(in_file)
    cache = read
    cache[in_file] ||= {}
    cache[in_file]['content']
  end

  ## Read the cache file
  def self.read
    return {} unless File.exist? @cache_file
    YAML.load_file @cache_file
  end

  ## Save the cache file
  def self.write(cache)
    FileUtils.mkdir_p File.dirname(@cache_file)
    File.write @cache_file, YAML.dump(cache)
  end
end

## Class to access metadata

class Metadata
  @metadata_file = 'data/metadata.yaml'

  ## Returns metadata for a page
  def self.for(fname)
    data = read
    data.select { |k| k['source'] == fname if k }.first
  end

  ## Updates metadata for a page
  def self.update(fname, page_dump = {})
    data = read
    data.delete self.for(fname)
    data << page_dump
    write(data)
  end

  ## Read the metadata from file
  def self.read
    return [] unless File.exist? @metadata_file
    YAML.load_file @metadata_file
  end

  ## Write the metadata to file
  def self.write(metadata)
    FileUtils.mkdir_p File.dirname(@metadata_file)
    File.write @metadata_file, YAML.dump(metadata)
  end
end

## My resume is a special beast who's markdown is templated.
## I also have a latex version that has to be rendered.
## The final pdf is rendered by the make file

class Resume
  def self.render_md
    @resume = YAML.load_file 'data/resume.yaml'
    template = ERB.new(File.read($template_src + '/Resume.md.erb'), 0, '-')
    md = template.result binding
    File.write $markdown_src + '/Resume.md', md
  end

  def self.render_tex
    @resume = YAML.load_file 'data/resume.yaml'
    template = ERB.new(File.read($template_src + '/Resume.tex.erb'), 0, '-')
    tex = template.result binding
    FileUtils.mkdir_p $tex_src
    File.write $tex_src + '/Resume.tex', tex
  end

  def self.render
    render_md
    render_tex
  end
end

## Class to render all the pages
class Site
  def self.init
    ## Clear the existing public_html directory
    FileUtils.rm_rf $public_html
    FileUtils.mkdir_p $public_html

    ## Symlink the needful
    FileUtils.symlink '../assets', $public_html
  end

  def self.render
    # Initialize the site
    init
    # Prerender Resume
    Resume.render
    # Pages have to be preloaded in order for the menus to work correctly
    $pages = []
    # Get the html pages
    Find.find($html_src).each do |page|
      $pages << Page.new(page) if page =~ /\.html$/
    end
    # Get the markdown pages
    Find.find($markdown_src).each do |page|
      $pages << Page.new(page) if page =~ /\.md$/
    end
    # Render each page
    $pages.each do |p|
      p.render
      puts "Rendered #{p.title}"
    end
  end
end

if ARGV[0] == 'resume'
  Resume.render
else
  Site.render
end
