class AddNameToRegions < ActiveRecord::Migration[6.0]
  def change
    add_column :regions, :name, :string
  end
end
