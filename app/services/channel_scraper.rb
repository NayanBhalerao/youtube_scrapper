require 'nokogiri'
require 'open-uri'
require 'selenium-webdriver'

class ChannelScraper
  def initialize(channel_url)
    @channel_url = channel_url
  end

  def scrape_videos
    # Set up Selenium in headless mode
    # options = Selenium::WebDriver::Firefox::Options.new(args: ['--headless']) # Headless mode
    # driver = Selenium::WebDriver.for :firefox, options: options
    # driver.get(@channel_url)
  
    # sleep(3) # Give the page some time to load initial content
  
    # # Scroll down the page to load more videos
    # last_height = driver.execute_script("return document.documentElement.scrollHeight")
    
    # loop do
    #   # Scroll down the page
    #   driver.execute_script("window.scrollTo(0, document.documentElement.scrollHeight);")
    #   sleep(3) # Give time for the page to load more videos
  
    #   new_height = driver.execute_script("return document.documentElement.scrollHeight")
    #   break if new_height == last_height # Exit the loop if no more new content is loaded
  
    #   last_height = new_height
    # end
  
    # Parse the page source after all videos have loaded
    # html = driver.page_source
    # doc = Nokogiri::HTML(html)
  
    # Collect unique video links
    # video_links = doc.css('a[href^="/watch"]').map do |link|
    #   "https://www.youtube.com#{link['href']}"
    # end.uniq
  
    video_links = ['https://www.youtube.com/watch?v=PzsRWH0n6O4',
                   'https://www.youtube.com/watch?v=4-EKS2-nW4s',
                   'https://www.youtube.com/watch?v=TZXj-LITY2E&t=8s']
    # Close the browser after collecting links
    # driver.quit
  
    # Scrape each video link
    video_links.each do |video_link|
      puts video_link
      video_scraper = VideoScrapper.new(video_link)
      video_scraper.scrape
    end
  end
  
  
end