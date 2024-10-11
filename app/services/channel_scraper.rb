require 'nokogiri'
require 'open-uri'
require 'selenium-webdriver'

class ChannelScraper
  def initialize(channel_url)
    @channel_url = channel_url
  end

  def scrape_videos
    # open this
    options = Selenium::WebDriver::Firefox::Options.new(args: ['--headless']) # Headless mode
    driver = Selenium::WebDriver.for :firefox, options: options
    driver.get(@channel_url)
  
    sleep(2)
  
    html = driver.page_source
    doc = Nokogiri::HTML(html)
  
    video_links = doc.css('a[href^="/watch"]').map do |link|
      "https://www.youtube.com#{link['href']}"
    end.uniq
    
    # video_links = ["https://www.youtube.com/watch?v=2qOZyyEwAvg",
    #   "https://www.youtube.com/watch?v=aWSb8uhYj1c",
    #   "https://www.youtube.com/watch?v=55mmDIJx6GU"]
    # open this
    driver.quit
  
    video_links.each do |video_link|
      puts video_link
      video_scraper = VideoScrapper.new(video_link)
      video_scraper.scrape
    end
  end
  
end