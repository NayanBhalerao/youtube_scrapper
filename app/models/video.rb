class Video < ApplicationRecord
    validates :url, uniqueness: true
end