$:.unshift File.dirname(__FILE__) + "/.."
require "strokedb"

StrokeDB::Config.build :default => true, :base_path => 'test/storages/playing3'

User = StrokeDB::Meta.new do
  def to_s
    self[:name]
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
    puts self.inspect
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
u = User.new(:name => "Yurii")
u.metas << Buyer
u.save!
apple = Product.create!(:name => "green apple", :price => 2,:quantity => 100)
pizza = Product.create!(:name => "big pizza", :price => 15,:quantity => 5)
u.buy!(apple)
u.buy!(pizza)

puts u.inspect

# config[:mem].sync_chained_storages!
# config.storages[:index_storage].clear!
