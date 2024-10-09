
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
    days_ago_text = description_full[/(\d+)\s(years?|months?|weeks?|days?)\sago/i]

    # date when the vedio is posted
    # Extract the specific posted date in formats like 'Sep 29, 2024'
    date_posted_text = description_full[/\w+\s\d{1,2},\s\d{4}/]
    
    # vidio description
    description = extract_description(description_full)

    # getting the exact duration of the video
    duration = extract_duration(driver)

    # updating to database
    Video.find_or_create_by(url: @video_url) do |video|
      video.title = title
      video.description = description
      video.view_count = view_count
      video.like_count = "-"
      video.comment_count = "-"
      video.duration = duration
      video.posted_at = date_posted_text
      video.days_ago = days_ago_text
      video.url = @video_url
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
end
