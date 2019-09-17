# frozen_string_literal: true

require 'csv'
require 'curb'
require 'nokogiri'
require 'mechanize'
require 'json'
require_relative 'command_line_parser'

robots_txt = 'https://www.petsonic.com/robots.txt'
TABLE_COLUMNS = %w[Name Price Image Relevance]
ROBOTS_DELAY = Nokogiri::HTML(Curl.get(robots_txt).body_str)
               .to_s
               .scan(/Crawl-delay.*/)[1]
               .scan(/\d+/)[0]
               .to_f / 1000.0

options = CommandLineParser.parse(ARGV)
base_url = options[:url] || 'https://www.petsonic.com/snacks-huesos-para-perros/'
file = options[:file] || 'results.csv'

links_to_categories = []

def no_products(html)
  html.xpath("//p[starts-with(@class, 'alert')]").text == 'No hay productos en esta categoría'
end

def error(html)
  html.xpath("//div[starts-with(@class, 'alert')]/p").text == 'Error 1'
end

def show_message(url, message)
  puts "Link #{url} to #{message} is not available"
end

def get_with_delay(url, message)
  sleep(ROBOTS_DELAY)
  http = Curl.get(url).body_str
  html = Nokogiri::HTML(http)

  if no_products(html)
    show_message(url, message)
    return false
  end

  if http.empty?
    show_message(url, message)
    return false unless message == 'product'
    url.to_s.gsub!('.com/', '.com/hobbit-alf-')
    sleep(ROBOTS_DELAY)
    http = Curl.get(url).body_str
    html = Nokogiri::HTML(http)

    if http.empty? || error(html) || no_products(html)
      show_message(url, message)
      return false
    end
  end

  print "Collect info from about #{message}"
  html
end

def links_to_categories_first_page(html)
  html.xpath("//div[@id='subcategories']/ul/li/a")
    .map { |el| el.attr 'href' }
end

def product_links(category_page)
  product_elements = category_page.xpath("//ul[@id='product_list']/li/div[1]/div/div[1]/a")
  product_elements.map { |element| element.attr 'href' }
end

def product_params(product_page)
  JSON.parse(
    product_page
    .xpath("//script[@type='text/javascript']")[0]
    .to_s
    .scan(/var combinations=(.*?)}};/)[0][0] + '}}'
  )
end

def show_category_name(category_page)
  puts category_page.xpath("//span[@class='cat-name']").text
end

def product_name(product_page)
  product_page.xpath("//h1[@class='product_main_name']").text
end

def product_actuality(product_page)
  product_page
  .xpath('//html/body/div[2]/div[1]/div/div[1]/div/div/div/div/div[2]/div[3]/p')
  .text
end

def product_price(product_page)
  product_page
  .xpath("//div[@id='attributes']/fieldset[@class='attribute_fieldset']")
  .map { |el| el }[0]
  .xpath(".//div/ul/li/label/span[@class='price_comb']")
  .map(&:text)
end

def product_image_url(product_page)
  product_page
  .xpath("//img[@id='bigpic']")
  .attr('src')
end

def proccess_product_link(product_page, csv)
  product_name = product_name(product_page)
  product_price = product_price(product_page)
  product_image_url = product_image_url(product_page)
  product_actuality = product_actuality(product_page)
  puts product_name

  product_weigths_and_image_ids = product_params(product_page).map do |_, value|
    [value['attributes_values'].map { |_, value| value }.join(' '), value['id_image']]
  end

  product_weigths_and_image_ids.each_with_index do |data, index|
    product_image_url.to_s.gsub!(/\d{#{data[1].to_s.length}}/, data[1].to_s) unless data[1] == -1

    csv << ["#{product_name} #{data[0]}",
            product_price[index],
            product_image_url,
            product_actuality]
  end
end

html = get_with_delay(base_url, "categories ")
show_category_name(html)

if html
  links_to_categories_first_page(html).each do |link|
    links_to_categories << link
    links_to_categories << link + '?p=2'
  end

  CSV.open(file, 'wb') do |csv|
    csv << TABLE_COLUMNS

    links_to_categories.each do |link_to_category|
      category_page = get_with_delay(link_to_category, "subcategory ")
      next unless category_page
      show_category_name(category_page)

      product_links(category_page).each do |product_link|
        product_page = get_with_delay(product_link, 'product')
        next unless product_page
        proccess_product_link(product_page, csv)
      end
    end
  end
end
