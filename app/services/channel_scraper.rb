class ChannelScraper
    def initialize(channle_url)
        @channel = Yt::Channel.new(url: channel_url)
    end

    def scrape_videos
        @channel.videos.each do |video|
          VideoScraper.new(video).scrape
        end
    end
end
