require File.dirname(__FILE__) + '/../../lib/strokedb'
require 'rubygems'
require 'ramaze'
require 'redcloth'

# strokewiki will run in port 7000 and uses WEBRick by default
# you can change it uncommenting these four lines below.
# Ramaze::Global.setup do |g|
#   g.port = 80
#   g.adapter = :mongrel
# end

StrokeDB.use_global_default_config!
StrokeDB::Config.build :default => true, :base_path => '.wiki.strokedb'
# This will be the default homepage name
HOME = 'Home'


Page = StrokeDB::Meta.new do
  
  validates_uniqueness_of :name
  
  on_new_document do |doc|
    doc[:body] ||= "I'm a boring page, please edit me!"
  end
  
  before_save do |doc|
    doc[:updated_at] = Time.now.ctime
  end
  
  def title
    name.gsub(/_/, ' ')
  end
 
  # A derivation of body, which is actually displayed when showing a page.
  # It has stuff like [[links]] resolved as HTML links or placeholders if the
  # linked to page does not already exist
  def display_body    
    # mostly taken from JunebugWiki, regexps this beautiful should be shared
    content = self.body.gsub(/\[\[([\w0-9A-Za-z -]+)[|]?([^\]]*)\]\]/) do
      page = title = $1.strip
      title = $2 unless $2.empty?
      page_url = page.gsub(/ /, '_')
 
      if Page.find(:name => page_url).first
        %Q{<a href="/show/#{page_url}">#{title}</a>}
      else
        %Q{<span>#{title}<a href="/new/#{page_url}">?</a></span>}
      end
    end
    RedCloth.new(content, []).to_html
  end
  
end
 
class MainController < Ramaze::Controller
  def index
    redirect("/show/#{HOME}")
  end
  
  def pages
    @pages = Page.find.sort { |a,b| a.name.downcase <=> b.name.downcase }
  end
  
  def show name,version=nil
    @page = Page.find(:name => name).first
    @page = @page.versions[version] if version
    redirect("/new?name=#{name}") unless @page
  end
  
  def versions name
    @page = Page.find(:name => name).first
    @versions = @page.versions.all
    redirect("/new?name=#{name}") unless @page
  end
  
  def new
    @page = Page.new(:name => request['name'])
  end

  def create name
    @page = Page.new(:name => name, :body => request['body'])
    @page.save!
    redirect("/show/#{@page.name}")
  end

  def edit name
    @page = Page.find(:name => name).first
  end

  def update name
    @page = Page.find(:name => name).first
    @page.body = request['body']
    @page.save!
    redirect("/show/#{@page.name}")
  end

  def delete name
    @page = Page.find(:name => name).first
    @page.delete!
    redirect("/")
  end
  
end
 
Ramaze.start
