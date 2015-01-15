class CreateRestaurants < ActiveRecord::Migration
  def self.up
    create_table :restaurants do |t|
      t.string :name , :null => false
      t.string :url
      t.integer :web, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :restaurants
  end
end