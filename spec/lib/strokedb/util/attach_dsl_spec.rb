require File.dirname(__FILE__) + '/../spec_helper'

describe "attach_dsl DSL :-)" do
  
  before(:each) do
    module MetaDSL
      def on_initialize(&block)
        store_dsl_options("on_initialize", block)
      end
    end

    module HasMany
      attach_dsl MetaDSL
      def has_many(*args)
        store_dsl_options("has_many", { :module => HasMany, :args => args } )
      end
      on_initialize do |doc|
        blah_blah
      end
    end
    
    module ValidatePresenceOf
      attach_dsl MetaDSL
      def validate_presence_of(*args)
        store_dsl_options("validate_presence_of", { :module => ValidatePresenceOf, :args => args } )
      end
      on_initialize do |doc|
        blah_blah
      end
    end

    module App1
      attach_dsl HasMany, ValidatePresenceOf
      has_many :blah, :blah => :blah
      validate_presence_of :blah, :blah
    end
  end
  
  it "should return a list of DSL options" do
    App1.dsl.keys.to_set.should == %w[has_many validate_presence_of].to_set
    App1.dsl["has_many"].should == {:module => HasMany, :args => [:blah, {:blah => :blah}]} 
    App1.dsl["has_many"][:module].dsl["on_initialize"].should be_a_kind_of(Proc)
  end
  
end