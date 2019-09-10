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

@product_urls = []

links_to_categories.each do |link_to_category|
  http = Curl.get( link_to_category )

  category_page = Nokogiri::HTML( http.body_str )

  if category_page.xpath("//p[starts-with(@class, 'alert')]").text != 'No hay productos en esta categoría'
    product_links = category_page.xpath("//ul[@id='product_list']/li/div[1]/div/div[1]/a")
    @product_urls  = product_links.map {|el| el.attr 'href'}.uniq

    @product_urls.each do |product_url|
      http = Curl.get( product_url )
      product_page = Nokogiri::HTML( http.body_str )
      product_name = product_page.xpath("//h1[@class='product_main_name']").text

      product_details = product_page.xpath("//ul[@class='attribute_radio_list']")
      product_weight = product_details.map { |el| el.xpath("//li/label/span[@class='radio_label']").text }
      product_price = product_details.map { |el| el.xpath("//li/label/span[@class='price_comb']").text }

      puts product_name
      puts product_weight
      puts product_price
    end
    
    if Curl.get( link_to_category + "?p=2").body_str.empty?
        puts "empty"
    end

    puts '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
  end
end

