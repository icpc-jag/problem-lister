# wrapper for PukiWiki

require 'date'
require 'mechanize'
require 'uri'

class PukiWiki
  include Enumerable

  Page = Struct.new(:name, :uri, :last_modified)

  def initialize(uri, encoding = 'UTF-8')
    @uri = uri.is_a?(URI::Generic) ? uri : URI.parse(uri.to_s)
    @encoding = encoding
    @agent = Mechanize.new
  end

  # set authentication credential
  def login(username, password)
    @agent.add_auth(@uri, username, password)
    @agent.head(@uri)
    self
  end

  # get the list of pages
  def list()
    today = Date.today
    @agent.get(@uri + '?cmd=list').search('div[@id="body"]/ul/li/ul/li')
      .map {|li| Page.new(li.xpath('./a/text()').to_s, li.xpath('./a/@href').to_s,
                          (today - li.xpath('./small/text()').to_s.gsub(/^\(|d\)$/, '').to_i).strftime('%Y/%m/%d')) }
  end ## XXX: any better way to obtain precise last-modified time?

  def each(&block)
    list.each(&block)
  end

  # get the source code of a page
  def get(name)
    name = name.name if name.is_a?(Page)
    @agent.get(@uri + "?cmd=source&page=#{escape(name)}").at('#source').text
  end

  private

  def escape(s)
    URI.encode_www_form_component(s.encode(@encoding))
  end
end
