# frozen_string_literal: true

require 'csv'
require 'curb'
require 'nokogiri'
require 'mechanize'
require 'json'
require_relative 'parser'

robots_txt = 'https://www.petsonic.com/robots.txt'
ROBOTS_DELAY = Nokogiri::HTML(Curl.get(robots_txt).body_str)
                 .to_s
                 .scan(/Crawl-delay.*/)[1]
                 .scan(/\d+/)[0]
                 .to_f / 1000.0

options = CommandLineParser.parse(ARGV)
base_url = options[:url] || 'https://www.petsonic.com/snacks-huesos-para-perros/'
file = options[:file] || 'results.csv'

links_to_categories = []

def get_with_delay(url, message)
  sleep ROBOTS_DELAY
  http = Curl.get(url).body_str

  if http.empty?
    puts "Link to #{message} is not available"
    return false
  end

  print "Collect info about #{message}"
  Nokogiri::HTML(http)
end

CSV.open(file, 'wb') do |csv|
  csv << %w[Name Price Image Relevance]
end

html = get_with_delay(base_url, "categories\n")

if html
  links_to_categories_first_page = html.xpath("//div[@id='subcategories']/ul/li/a")
                                    .map { |el| el.attr 'href' }

  links_to_categories_first_page.each do |link|
    links_to_categories << link
    links_to_categories << link + '?p=2'
  end

  links_to_categories.each do |link_to_category|
    category_page = get_with_delay(link_to_category, "category\n")

    next unless category_page &&
                category_page.xpath("//p[starts-with(@class, 'alert')]").text != 'No hay productos en esta categoría'

    product_elements = category_page.xpath("//ul[@id='product_list']/li/div[1]/div/div[1]/a")
    product_links = product_elements.map { |element| element.attr 'href' }

    product_links.each do |product_link|
      product_page = get_with_delay(product_link, 'product')

      next unless product_page

      actual_product_weigths = []
      product_image_ids = []
      product_image_urls = []

      product_name = product_page.xpath("//h1[@class='product_main_name']").text
      print "#{product_name}\n"
      product_params = JSON.parse(product_page.xpath("//script[@type='text/javascript']")[0]
                                  .to_s
                                  .scan(/var combinations=(.*?)}};/)[0][0] + '}}')
      product_params.each do |_, value|
        actual_product_weigths << value['attributes_values']
                                  .map { |_, value| value }.join(' ')
        product_image_ids << value['id_image']
      end

      product_actuality = product_page
                          .xpath('//html/body/div[2]/div[1]/div/div[1]/div/div/div/div/div[2]/div[3]/p')
                          .text

      product_fieldset = product_page
                         .xpath("//div[@id='attributes']/fieldset[@class='attribute_fieldset']")
                         .map { |el| el }[0]

      product_weights = product_fieldset
                        .xpath(".//div/ul/li/label/span[@class='radio_label']")
                        .map(&:text)
      product_price = product_fieldset
                      .xpath(".//div/ul/li/label/span[@class='price_comb']")
                      .map(&:text)
      product_radio_value = product_fieldset
                            .xpath('.//div/ul/li/input')
                            .map { |el| el.attr('value') }
      product_help_value = product_fieldset.text.split(' ')[0][0..-2]

      product_weights.each_with_index do |product_weight, index|
        product_weigth_link = "#{product_link}#/#{product_radio_value[index]}-#{product_help_value}-#{product_weight.gsub(' ', '_')}"
                                .downcase
        product_weigth_page = get_with_delay(product_weigth_link,
                                             "product weigth #{product_weight}\n")
        next if product_weigth_page
        product_image_urls << product_page
                              .xpath("//img[@id='bigpic']")
                              .attr('src')
      end

      product_image_urls.each_with_index do |_, index|
        if product_image_ids[index] != -1
          actual_image_substring = product_image_ids[index].to_s
          product_image_urls[index] = product_image_urls[index]
                                      .to_s
                                      .gsub(/\d{#{actual_image_substring.length}}/, actual_image_substring.to_s)
        end

        CSV.open(file, 'a+') do |csv|
          csv << ["#{product_name} #{actual_product_weigths[index]}",
                  product_price[index],
                  product_image_urls[index],
                  product_actuality]
        end
      end
    end
  end
end
