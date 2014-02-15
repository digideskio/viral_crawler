class Article < ActiveRecord::Base
  has_attached_file :thumbnail

  validates_uniqueness_of :url
  validates_attachment_content_type :thumbnail, :content_type => %w(image/jpeg image/jpg image/png)
end
