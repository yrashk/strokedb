$:.unshift File.dirname(__FILE__) + "/.."
require "strokedb"

config = StrokeDB::Config.new(true)

config.add_storage :mem, :memory_chunk
config.add_storage :fs, :file_chunk, 'test/storages/test'

config.chain :mem, :fs
config[:mem].authoritative_source = config[:fs]

config.add_storage :index_storage, :inverted_list_file, 'test/storages/index'
config.add_index :default, :inverted_list, :index_storage

config.add_store :default, :skiplist, :mem, :cut_level => 4

User = StrokeDB::Meta.new do
  def to_s
    name
  end
end
Buyer = StrokeDB::Meta.new do

  on_initialization do |buyer|
    unless buyer[:balance]
      puts "Providing $100 to #{buyer}, since he is a new buyer"
      buyer.balance = 100 
    end
    unless buyer[:products_bought]
      buyer.products_bought = []
    end
  end
  after_save do |buyer|
    puts "Now #{buyer} has #{buyer.products_bought.empty? ? 'nothing' : buyer.products_bought.map(&:name).to_sentence} (and his balance is $#{buyer.balance})"
  end
  
  def buy!(product)
    puts "#{self} is buying #{product}"
    product.checkout!
    self.products_bought << product
    self.balance -= product.price
    save!
  end
end

Product = StrokeDB::Meta.new do
  after_save do |product|
    puts "#{product.quantity} items of #{product} left"
  end
  
  def to_s
    "'#{name}' for $#{price}"
  end
  
  def checkout!
    self.quantity -= 1
    save!
  end
end

puts "Creating user..."
u = User.create!(:name => "Yurii")
u.metas << Buyer
u.save!
apple = Product.create!(:name => "green apple", :price => 2,:quantity => 100)
pizza = Product.create!(:name => "big pizza", :price => 15,:quantity => 5)
u.buy!(apple)
u.buy!(pizza)


# config[:mem].sync_chained_storages!
# config.storages[:index_storage].clear!
