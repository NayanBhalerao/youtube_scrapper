class VideosController < ApplicationController
  def index
    @videos = Video.all
    # @videos.each do |vedio|

    # end
  end
end