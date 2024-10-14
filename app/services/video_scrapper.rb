
class VideoScrapper
  def initialize(video_url)
    @video_url = video_url
    @video_id = extract_video_id(video_url)
  end

  def scrape
    options = Selenium::WebDriver::Firefox::Options.new(args: ['--headless']) # Headless mode
    driver = Selenium::WebDriver.for :firefox, options: options
    driver.get(@video_url)
  
    sleep(3)

    html = driver.page_source
    doc = Nokogiri::HTML(html)
    
    title = doc.css('h1.title yt-formatted-string').text.strip
    description_full = doc.css('div#description').text.strip 
    
    view_count_text = description_full[/(\d+(?:[,.]\d+)?[KM]?\sviews)/i]
    view_count = if view_count_text
                  # Handle large numbers like 3.7K, 2M, etc.
                  multiplier = case view_count_text
                                when /K/i then 1_000
                                when /M/i then 1_000_000
                                else 1
                              end
                  view_count_text.scan(/\d+(?:[,.]\d+)?/).join('').to_f * multiplier
                else
                  0
                end

    # Extract "days ago" posting pattern
    days_ago_text = description_full[/(\d+)\s(years?|months?|weeks?|days?|hours?|minutes?|seconds?)\sago/i]

    # date when the vedio is posted
    # Extract the specific posted date in formats like 'Sep 29, 2024'
    date_posted_text = description_full[/\w+\s\d{1,2},\s\d{4}/]
    
    # vidio description
    description = extract_description(description_full)

    # getting the exact duration of the video
    duration = extract_duration(driver)

    # get comments count
    comments_count = get_comments_count(driver)

    # get likes count
    likes_count = get_likes_count(driver)

    # get the thumbnail URL
    thumbnail_url = get_thumbnail_url(driver)

    # updating to database
    Video.find_or_create_by(url: @video_url) do |video|
      video.title = title
      video.description = description
      video.view_count = view_count
      video.like_count = likes_count
      video.comment_count = comments_count
      video.duration = duration
      video.posted_at = date_posted_text
      video.days_ago = days_ago_text
      video.url = @video_url
      video.thumbnail_url = thumbnail_url
    end
    
    driver.quit # Close the browser
  end

  private

  def extract_description(description_full)
    # Remove the view count and any initial unwanted text
    description = description_full.gsub(/\d+[K]?\s+views.*?Show less\s+/im, '').strip
    
    # Handle "more" section by using a regex that captures everything before it
    if description =~ /…more.*$/ 
      description.gsub!(/(.*?)\.\.\.more.*$/, '\1')
    end
    
    # Remove any transcript mentions and other unnecessary parts
    description.gsub!(/Transcript.*?Show transcript.*?(\n|$)/m, '')
    
    # Clean up whitespace
    description = description.gsub(/\s+/, ' ').strip if description
    
    # Extract everything after "Show less" (if present)
    if description =~ /Show less\s+(.*)/m
      description = $1.strip
    end
    # Return the final cleaned description
    description
  end
  

  # Extract YouTube video ID from the URL
  def extract_video_id(url)
    uri = URI.parse(url)
    CGI.parse(uri.query)['v'].first
  end
  
  # Extract the video duration using Selenium and JavaScript
  def extract_duration(driver)
    # This JavaScript query fetches the duration of the video by interacting with the YouTube video player
    script = <<-JS
      var video = document.querySelector('video');
      return video ? video.duration : null;
    JS

    # Execute JavaScript to get the video duration
    duration_in_seconds = driver.execute_script(script)

    # If duration is present, convert it to a readable format (e.g., "1:30" or "1:02:15")
    return format_duration(duration_in_seconds) if duration_in_seconds

    nil # Return nil if duration not found
  end

  # Convert duration in seconds to "HH:MM:SS" format
  def format_duration(seconds)
    return nil if seconds.nil?
    
    hours = (seconds / 3600).to_i
    minutes = ((seconds % 3600) / 60).to_i
    seconds = (seconds % 60).to_i

    if hours > 0
      format("%02d:%02d:%02d", hours, minutes, seconds)
    else
      format("%02d:%02d", minutes, seconds)
    end
  end

  def get_comments_count(driver)
    driver.manage.window.maximize
    wait = Selenium::WebDriver::Wait.new(timeout: 10)
    # XPaths for title and comments count
    title_xpath = "//div[@class='style-scope ytd-video-primary-info-renderer']/h1"
    alternative_title = "//*[@id='title']/h1"
    comments_xpath = "//div[@id='title']//*[@id='count']//span[1]"
    # Scroll down to load comments count
    driver.execute_script("window.scrollBy(0, arguments[0]);", 600)
    # Retrieve comments count
    begin
      v_comm_cnt = wait.until { driver.find_element(:xpath, comments_xpath).text }
      puts "\n \n Video has #{v_comm_cnt} comments"
    rescue Selenium::WebDriver::Error::TimeoutError
      puts "\n \n Could not retrieve comments count"
    end
    v_comm_cnt.nil? ? 0 : v_comm_cnt.to_i
  end

  # get the likes count
  def get_likes_count(driver)
    wait = Selenium::WebDriver::Wait.new(timeout: 10)

    begin
      # Wait for the like button to be present
      like_button = wait.until { driver.find_element(:xpath, "//button[contains(@aria-label, 'like this video')]") }
  
      # Extract the aria-label attribute
      like_aria_label = like_button.attribute("aria-label")
      puts "Aria Label: #{like_aria_label}" # Debugging line
  
      # Adjusted regex pattern to capture the number of likes
      if like_aria_label && match_data = like_aria_label.match(/(\d{1,3}(?:,\d{3})*)\s+other people/i)
        like_count = match_data[1].gsub(',', '').to_i # Remove commas and convert to integer
        puts "Like Count: #{like_count}"
      else
        puts "Like Count not found"
        like_count = 0
      end
    rescue Selenium::WebDriver::Error::NoSuchElementError
      puts "Like button not found"
      like_count = 0
    rescue Selenium::WebDriver::Error::TimeoutError
      puts "Timed out waiting for like button"
      like_count = 0
    end
  
    like_count
  end

  # get the thumbnail url
  def get_thumbnail_url(driver)
    # Assuming you want to fetch the thumbnail of the current video being played
    wait = Selenium::WebDriver::Wait.new(timeout: 10)
    
    begin
      # XPath to find the thumbnail image on the video page
      thumbnail_element = wait.until { driver.find_element(:xpath, "//link[@rel='image_src']") }
      thumbnail_url = thumbnail_element.attribute("href")
      puts "Thumbnail URL: #{thumbnail_url}" # Debugging line
    rescue Selenium::WebDriver::Error::NoSuchElementError
      puts "Thumbnail not found"
      thumbnail_url = nil
    rescue Selenium::WebDriver::Error::TimeoutError
      puts "Timed out waiting for thumbnail"
      thumbnail_url = nil
    end

    thumbnail_url
  end
end