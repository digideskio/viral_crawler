class Article < ActiveRecord::Base
  has_attached_file :thumbnail, :styles => { :small => "80x80>" }

  validates_uniqueness_of :url
  validates_attachment_content_type :thumbnail, :content_type => /.*/
end
