require 'csv'
require 'curb'
require 'nokogiri'
require_relative 'parser'

base_url = 'https://www.petsonic.com/snacks-huesos-para-perros/'
alt_url = 'https://www.petsonic.com/hobbit-half/'
file = 'results.csv'

# parse command line params
options = CommandLineParser.parse(ARGV)

http = Curl.get(base_url)
html = Nokogiri::HTML(http.body_str)

links_to_categories = html.xpath("//div[@id='subcategories']/ul/li/a").map { |el| el.attr 'href' }

puts links_to_categories
