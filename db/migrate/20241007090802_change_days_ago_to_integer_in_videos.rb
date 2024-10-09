class ChangeDaysAgoToIntegerInVideos < ActiveRecord::Migration[7.1]
  def up
    change_column :videos, :days_ago, :string
  end

  def down
    change_column :videos, :days_ago, :integer
  end
end