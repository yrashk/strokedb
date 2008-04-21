require File.dirname(__FILE__) + '/spec_helper'

describe View do
  
  before(:each) do
    setup_default_store
    
    post_comments = View.new do |view|
      def view.map(doc)
       [ [doc, doc] ]
      end
    end
  end
  
end


