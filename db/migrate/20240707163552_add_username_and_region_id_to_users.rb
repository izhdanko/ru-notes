class AddUsernameAndRegionIdToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :username, :string
    add_column :users, :region_id, :integer
  end
end
