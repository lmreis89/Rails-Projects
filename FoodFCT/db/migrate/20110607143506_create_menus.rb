class CreateMenus < ActiveRecord::Migration
  def self.up
    create_table :menus do |t|

      t.string :meal, :null => false
      t.string :description, :null => false

      t.references :restaurant
      t.timestamps
    end
  end

  def self.down
    drop_table :menus
  end
end
