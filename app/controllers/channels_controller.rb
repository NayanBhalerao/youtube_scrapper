class ChannelsController < ApplicationController
  def scrape
    channel_url = params[:channel_url]
    scraper = ChannelScraper.new(channel_url)
    scraper.scrape_videos

    redirect_to videos_path, notice: "Videos scraped successfully!"
  end
end