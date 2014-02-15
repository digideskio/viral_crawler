class RemoveThumbUrlFromArticle < ActiveRecord::Migration
  def up
    remove_column :articles, :thumb_url
  end

  def down
    add_column :articles, :thumb_url, :text
  end
end
