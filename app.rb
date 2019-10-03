# frozen_string_literal: true

require 'csv'
require 'curb'
require 'nokogiri'
require 'mechanize'
require 'json'
require_relative 'command_line_parser'

robots_txt = 'https://www.petsonic.com/robots.txt'
TABLE_COLUMNS = %w[Name Price(€) Image Relevance]
ROBOTS_DELAY = Nokogiri::HTML(Curl.get(robots_txt).body_str)
               .to_s
               .scan(/Crawl-delay.*/)[1]
               .scan(/\d+/)[0]
               .to_f / 1000.0

options = CommandLineParser.parse(ARGV)
base_url = options[:url] || 'https://www.petsonic.com/snacks-huesos-para-perros/'
file = options[:file] || 'results.csv'

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

  if http.empty?
    show_message(url, message)
    return false unless message == 'about product'
    url.to_s.gsub!('.com/', '.com/hobbit-alf-')
    sleep(ROBOTS_DELAY)
    http = Curl.get(url).body_str
    html = Nokogiri::HTML(http)

    if http.empty? || error(html)
      show_message(url, message)
      return false
    end
  end

  print "Collect info #{message}"
  html
end

def product_links_from_single_page(category_page)
  product_elements = category_page.xpath("//ul[@id='product_list']/li/div[@class='product-container']/div/div[@class='pro_first_box ']/a")
  product_elements.map { |element| element.attr 'href' }
end

def product_weigth_combination(attribute)
  attribute.map { |_, value| value }.join(' ')
end

def parse_product_params(product_page, xpath, regexp)
  json_string = product_page.xpath(xpath)[0].to_s.scan(regexp)
  JSON.parse(json_string[0][0]) unless json_string.empty?
end

def product_weigths_and_image_ids(product_page)
  product_combinations = parse_product_params(product_page, "//script[@type='text/javascript']", /var combinations=(.*?);var/)
  price_multiplier = parse_product_params(product_page, "//script[@type='text/javascript']", /productBasePriceTaxExcluded=(.*?);var/).to_f / parse_product_params(product_page, "//script[@type='text/javascript']", /productBasePriceTaxIncl=(.*?);var/).to_f

  if product_combinations
    return product_combinations.map{ |_, value| [product_weigth_combination(value['attributes_values']), value['id_image'].to_s, (value['price'].to_f / price_multiplier).round(2)] }.uniq
  else
    product_combinations = parse_product_params(product_page, "//script[@data-keepinline='true']", /\"products\":\[(.*?)\]}},/)
    return [[product_combinations['variant'], '-1', product_combinations['price']]]
  end
end

def show_category_name(category_page)
  puts category_page.xpath("//span[@class='cat-name']").text
end

def product_name(product_page)
  product_page.xpath("//h1[@class='product_main_name']").text
end

def product_actuality(product_page)
  product_page
  .xpath("//div[@class='substitucion-text-container']/p")
  .text
end

def product_image_url(product_page)
  product_page
  .xpath("//img[@id='bigpic']")
  .attr('src').to_s
end

def product_weigth_image_url(product_image_url, image_id)
  image_id == '-1' ? product_image_url : product_image_url.gsub(/.com\/\d+/, ".com/#{image_id}")
end

def proccess_product_link(product_page, results)
  product_name = product_name(product_page)
  puts product_name
  product_image_url = product_image_url(product_page)
  product_actuality = product_actuality(product_page)


  product_weigths_and_image_ids(product_page).each_with_index do |data, index|
    results << ["#{product_name} #{data[0]}",
                data[2],
                product_weigth_image_url(product_image_url, data[1]),
                product_actuality]
  end
end

def next_page_link(html)
  html.xpath("//link[@rel='next']").attr('href')
end

def category_products_links(html)
  category_products_links = []
  loop do
    next_page_link = next_page_link(html)
    product_links_from_single_page(html).map{ |link| category_products_links << link }
    break unless next_page_link
    html = get_with_delay(next_page_link, "from page #{next_page_link.to_s.match(/\d+/)}\n")
  end
  category_products_links.uniq
end

html = get_with_delay(base_url, 'about category ')
show_category_name(html)
puts 'Collect info from page 1'
category_products_links = category_products_links(html)

unless category_products_links.empty?
  CSV.open(file, 'wb') do |csv|
    csv << TABLE_COLUMNS
    results = []

    category_products_links.each do |product_link|
      product_page = get_with_delay(product_link, 'about product')
      next unless product_page
      proccess_product_link(product_page, results)
    end

    results.uniq!
    results.map{ |row| csv << row }
  end
end
