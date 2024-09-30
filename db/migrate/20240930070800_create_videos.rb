class CreateVideos < ActiveRecord::Migration[7.1]
  def change
    create_table :videos do |t|
      t.string :title
      t.text :description
      t.string :url
      t.integer :view_count
      t.integer :like_count
      t.integer :comment_count

      t.timestamps
    end
  end
end
