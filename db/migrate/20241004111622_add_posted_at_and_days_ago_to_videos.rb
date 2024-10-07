class AddPostedAtAndDaysAgoToVideos < ActiveRecord::Migration[7.1]
  def change
    add_column :videos, :posted_at, :date
    add_column :videos, :days_ago, :integer
  end
end
