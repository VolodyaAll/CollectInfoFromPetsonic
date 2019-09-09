require 'csv'
require 'curb'
require 'nokogiri'
require_relative 'parser'

base_url = 'https://www.petsonic.com/snacks-huesos-para-perros/'
alt_urrl = 'https://www.petsonic.com/hobbit-half/'
file = 'results.csv'

# parse command line params
options = CommandLineParser.parse(ARGV)

http = Curl.get(base_url)
puts http.body_str
# # getting repo adresses
# gems['gems'].each do |gem|
#   url = base_url + gem
#   begin
#     doc = Nokogiri::HTML(URI.open(url))
#   rescue OpenURI::HTTPError => err
#     puts "There is no '#{gem}' gem on https://rubygems.org. Exception encountered: #{err}"
#   else
#     gem_repo_url[gem] = doc.css('a#code, a#home').last['href']
#   end
# end

# # getting array of gems with its params from github
# gem_repo_url.each do |key, value|
#   gem_array = []
#   begin
#     doc = Nokogiri::HTML(URI.open(value))
#     doc_for_used_by = Nokogiri::HTML(URI.open(value + '/network/dependents'))
#   rescue OpenURI::HTTPError => err
#     puts "Github repositiry '#{gem}' gem not found. Exception encountered: #{err}"
#   else
#     gem_array << key

#     # getting used_by
#     gem_array << doc_for_used_by.css("a[class = 'btn-link selected']").text.gsub!(/[^\d]/, '').to_i

#     # getting watched, stars, forks
#     doc.css('a.social-count').each do |score|
#       gem_array << score.text.gsub!(/[^\d]/, '').to_i
#     end

#     # getting contributors
#     gem_array << doc.css("span[class ='num text-emphasized']")[3].text.to_i

#     # getting issues
#     gem_array << doc.at_css('.Counter').text.to_i
#   end
#   top_gems << gem_array
# end
