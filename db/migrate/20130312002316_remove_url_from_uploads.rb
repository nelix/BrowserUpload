class RemoveUrlFromUploads < ActiveRecord::Migration
  def change
  	remove_column :uploads, :url
  end
end
