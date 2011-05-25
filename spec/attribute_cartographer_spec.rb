require 'spec_helper'

describe AttributeCartographer do
  after(:each) do
    TestClass.instance_variable_set :@mapper, nil
  end

  let(:klass) {
    class TestClass
      include AttributeCartographer
    end
  }

  describe "#initialize" do
    context "with nothing mapped" do
      it "does not try to map anything when map was not called" do
        lambda { klass.new(a: :b) }.should_not raise_error
      end
    end

    context "with attributes that don't match mapped values" do
      before { klass.map :a, :b, ->(v) { v + 1 } }

      it "doesn't map attributes when no mappable attribute was passed in" do
        lambda { klass.new(c: :d).b }.should raise_error(NoMethodError)
      end
    end
  end

  describe "#original_attributes" do
    it "returns any attributes given to initialize" do
      klass.new(a: :b).original_attributes.should == { a: :b }
    end
  end

  describe "#mapped_attributes" do
    before { klass.map :a, :b, ->(v) { v + 1 } }

    it "returns any attributes mapped by the mapper" do
      klass.new(a: 1).mapped_attributes.should == { b: 2 }
    end
  end

  describe ".map" do
    context "with a single argument" do
      context "and no lambda" do
        before { klass.map :a }

        it "creates an instance method matching the key name" do
          klass.new(:a => :a_value).a.should == :a_value
        end
      end

      context "and a 1-arity lambda" do
        before { klass.map :a, ->(v) { v.downcase } }

        it "creates an instance method matching the key name, mapping the value with the lambda" do
          klass.new(:a => "STRING").a.should == "string"
        end
      end

      context "and a 2-arity lambda" do
        before { klass.map :A, ->(k,v) { [k.downcase, v.downcase] } }

        it "maps the key and value using the lambda and creates an instance method accordingly" do
          klass.new(A: "STRING").a.should == "string"
        end

        it "doesn't raise an error when the attributes hash is missing a mapped key" do
          lambda { klass.new(c: 2) }.should_not raise_error
        end
      end
    end

    context "with two arguments" do
      context "and no lambda" do
        before { klass.map :a, :b }

        it "maps the from to the to" do
          klass.new(:a => :a_value).mapped_attributes[:b].should == :a_value
        end

        it "maps the to to the from" do
          klass.new(:b => :b_value).mapped_attributes[:a].should == :b_value
        end
      end

      context "and a single lambda" do
        before { klass.map :a, :b, ->(v) { v.downcase } }

        it "creates an instance method matching the key name, mapping the value with the lambda" do
          klass.new(:a => "STRING").b.should == "string"
        end
      end

      context "and two lambdas" do
        before { klass.map :a, :b, ->(v) { v.downcase }, ->(v) { v.upcase } }

        it "creates an instance method matching the second key name, mapping the value with the first lambda" do
          klass.new(a: "STRING").b.should == "string"
        end

        it "creates an instance method matching the first key name, mapping the value with the second lambda" do
          klass.new(b: "string").a.should == "STRING"
        end
      end

      context "and a >1-arity lambda" do
        it "raises an error" do
          lambda { klass.map :a, :b, ->(k,v) { v + 1 } }.should raise_error(AttributeCartographer::InvalidArgumentError)
        end
      end
    end

    context "with an array" do
      context "with no lambda" do
        before { klass.map [:a, :b] }

        it "creates a method named for each key" do
          instance = klass.new(a: :a_value, b: :b_value)
          instance.a.should == :a_value
          instance.b.should == :b_value
        end

        it "doesn't raise an error when the attributes hash is missing a mapped key" do
          lambda { klass.new(a: :a_value).b }.should raise_error(NoMethodError)
        end
      end

      context "and a 1-arity lambda" do
        before { klass.map [:a, :b], ->(v) { v.downcase } }

        it "creates a method named for each key using the lambda to map the values" do
          instance = klass.new(a: "STRING1", b: "STRING2")
          instance.a.should == "string1"
          instance.b.should == "string2"
        end
      end

      context "and a 2-arity lambda" do
        before { klass.map [:A, :B], ->(k,v) { [k.downcase, v.downcase] } }

        it "maps the key and value using the lambda and creates an instance method accordingly" do
          instance = klass.new(A: "ASTRING", B: "BSTRING")
          instance.a.should == "astring"
          instance.b.should == "bstring"
        end
      end
    end
  end
end
