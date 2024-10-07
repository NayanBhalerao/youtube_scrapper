class VideoScrapper
  def initialize(video_url)
    @video_url = video_url
  end

  def scrape
    options = Selenium::WebDriver::Firefox::Options.new(args: ['--headless']) # Headless mode
    driver = Selenium::WebDriver.for :firefox, options: options
    driver.get(@video_url)

    sleep(5)
  
    html = driver.page_source
    doc = Nokogiri::HTML(html)
    
    title = doc.css('h1.title yt-formatted-string').text.strip
    description_full = doc.css('div#description').text.strip 
    
    # view_count_text = doc.at_css('span.inline-metadata-item.style-scope.ytd-video-meta-block')&.text
    # view_count = view_count_text ? view_count_text.scan(/\d+/).join('').to_i : 0
    like_count = doc.at_css('yt-formatted-string#text[aria-label]')&.attr('aria-label')&.scan(/\d+/)&.join('').to_i || 0
    comment_count = doc.at_css('h2#count yt-formatted-string')&.text&.scan(/\d+/)&.join('').to_i || 0
    duration = doc.css('ytd-thumbnail-overlay-time-status-renderer span').collect do |r|
      r.text.strip.split(":").map(&:to_i).reduce { |a, b| a * 60 + b }
    end


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
    days_ago_text = description_full[/(\d+)\s(years?|months?|weeks?|days?)\sago/i]

    # extracting only the description text
    
    
    date_posted_text = description_full[/\w+\s\d{1,2},\s\d{4}/]
    
    
    description = extract_description(description_full)
    
    
    # Extract the specific posted date in formats like 'Sep 29, 2024'
    date_posted_text = description_full[/\w+\s\d{1,2},\s\d{4}/]

    
    Video.find_or_create_by(url: @video_url) do |video|
      video.title = title
      video.description = description
      video.view_count = view_count
      video.like_count = like_count
      video.comment_count = comment_count
      video.duration = duration
      video.posted_at = date_posted_text
      video.days_ago = days_ago_text
      video.url = video.url
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
    description.gsub!(/\s+/, ' ').strip!
    
    # Extract everything after "Show less" (if present)
    if description =~ /Show less\s+(.*)/m
      description = $1.strip
    end

    # Return the final cleaned description
    description
  end
  
  
end