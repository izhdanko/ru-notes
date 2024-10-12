class AddRegionToPosts < ActiveRecord::Migration[6.0]
  def change
    add_reference :posts, :region, null: false, foreign_key: true
  end
end
