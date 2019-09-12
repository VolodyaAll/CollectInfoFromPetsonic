require 'csv'
require 'curb'
require 'nokogiri'
require 'mechanize'
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
      puts product_name

      product_fieldsets = product_page.xpath("//div[@id='attributes']/fieldset[@class='attribute_fieldset']").map 
      puts product_fieldsets.size

      product_fieldsets.each do |fieldset|
        product_weights = fieldset.xpath("//div/ul/li/label/span[@class='radio_label']").map { |el| el.text }
        product_price = fieldset.xpath("//div/ul/li/label/span[@class='price_comb']").map { |el| el.text }
        product_radio_value = fieldset.xpath("//div/ul/li/input").map { |el| el.attr('value') }
        product_help_value = fieldset.text.split(' ')[0][0..-2]

        
        product_weights.each_with_index do |product_weight, index|
          product_weigth_url = "#{product_url}#/#{product_radio_value[index]}-#{product_help_value}-#{product_weight.gsub(' ', '_')}".downcase
          puts product_weigth_url
        end

      end
    end
    
    if Curl.get( link_to_category + "?p=2").body_str.empty?
        puts "empty"
    end

    puts '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
  end
end

