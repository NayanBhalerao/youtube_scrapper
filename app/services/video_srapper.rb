class VideoScraper
    def initialize(video)
      @video = video
    end
  
    def scrape
      video_details = {
        title: @video.title,
        description: @video.description,
        url: @video.url,
        view_count: @video.view_count,
        like_count: @video.like_count,
        comment_count: @video.comment_count
      }
  
      Video.find_or_create_by(url: @video.url).update(video_details)
    end
end