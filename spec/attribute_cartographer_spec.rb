require 'spec_helper'

describe AttributeCartographer do
  let(:klass) do
    Class.new do
      include AttributeCartographer
    end
  end

  describe "#initialize" do
    it "doesn't require an argument" do
      expect{ klass.new }.to_not raise_error
    end
  end

  describe "#original_attributes" do
    it "is the attributes given on initialize" do
      attrs = { a: :b }
      returned_attrs = klass.new(attrs).original_attributes
      expect(returned_attrs).to eq attrs
    end
  end

  describe "#mapped_attributes" do
    context "with no mapping" do
      it 'should be empty' do
        params = { "Attribute" => "Value" }
        mapping = klass.new(params).mapped_attributes
        expect(mapping).to eq({})
      end
    end

    context "with a mapping" do
      before { klass.map "Attribute", "attribute" }

      context "and no attributes to map" do
        it 'should be empty' do
          mapping = klass.new({}).mapped_attributes
          expect(mapping).to eq({})
        end
      end

      context "and attributes to map" do
        it 'maps the relevant attributes' do
          params = { 'Attribute' => 'Value' }
          expected_mapping =  { "attribute" => "Value" }
          mapping = klass.new(params).mapped_attributes
          expect(mapping).to eq expected_mapping
        end
      end
    end
  end

  describe ".map" do
    context "with a single argument" do
      context "and no lambda" do
        before { klass.map "Attribute" }

        it "creates an entry in mapped_attributes matching the key name" do
          mapping = klass.new("Attribute" => "Value").mapped_attributes
          expect(mapping['Attribute']).to eq "Value"
        end

        it "creates an entry in unmapped_attributes matching the key name" do
          mapping = klass.new("Attribute" => "Value").unmapped_attributes
          expect(mapping['Attribute']).to eq "Value"
        end
      end

      context "and a 1-arity lambda" do
        before { klass.map "Attribute", ->(v) { v.downcase } }

        it "creates an entry in mapped_attributes matching the key name,
            mapping the value with the lambda" do
          mapping = klass.new("Attribute" => "Value").mapped_attributes
          expect(mapping["Attribute"]).to eq "value"
        end

        it 'does not create an entry in the unmapped attributes' do
          mapping = klass.new("Attribute" => "Value").unmapped_attributes
          expect(mapping).to eq({})
        end
      end

      context "and a 2-arity lambda" do
        before { klass.map "Attribute", ->(k,v) { [k.downcase, v.downcase] } }

        it "creates an entry in mapped_attributes using the lambda for the key and value" do
          mapping = klass.new("Attribute" => "Value").mapped_attributes
          expected_mapping = { 'attribute' => 'value' }
          expect(mapping).to eq expected_mapping
        end

        it "doesn't raise an error when the attributes hash is missing a mapped key" do
          expect{ klass.new("OtherAttribute" => "OtherValue") }.to_not raise_error
        end
      end
    end

    context "with two arguments" do
      context "and no lambda" do
        before { klass.map "Attribute", "attribute" }

        context "with attributes matching the left key, passing the value through" do
          it "maps the left key to the right key" do
            mapping = klass.new("Attribute" => "Value").mapped_attributes
            expect(mapping['attribute']).to eq 'Value'
          end
        end

        context "with attributes matching the right key, passing the value through" do
          it "maps the right key to the left key" do
            mapping = klass.new("attribute" => "Value").unmapped_attributes
            expect(mapping['Attribute']).to eq 'Value'
          end
        end
      end

      context "and a single lambda" do
        before { klass.map "Attribute", "attribute", ->(v) { v.downcase } }

        context "with attributes matching the left key" do
          it "maps the left key to the right key using the lambda to alter the value" do
            mapping = klass.new("Attribute" => "Value").mapped_attributes
            expect(mapping['attribute']).to eq 'value'
          end
        end

        context "with attributes matching the right key" do
          it "doesn't map the right key as it's a one-way mapping" do
            mapping = klass.new("attribute" => "value").mapped_attributes
            expect(mapping['Attribute']).to eq nil
          end
        end
      end

      context "and two lambdas" do
        before do
          klass.map "Attribute", "attribute", ->(v) { v.downcase }, ->(v) { v.upcase }
        end

        context "with attributes matching the left key" do
          it "maps the left key to the right key, using the first lambda to map the value" do
            mapping = klass.new("Attribute" => "Value").mapped_attributes
            expect(mapping['attribute']).to eq 'value'
          end
        end

        context "with attributes matching the right key" do
          it "maps the right key to the left key, using the second lambda to map the value" do
            mapping = klass.new("attribute" => "Value").unmapped_attributes
            expect(mapping['Attribute']).to eq 'VALUE'
          end
        end
      end

      context "and a >1-arity lambda" do
        it "raises an error" do
          expect{ klass.map :a, :b, ->(k,v) { v + 1 } }.
            to raise_error(AttributeCartographer::InvalidArgumentError)
        end
      end

      context "and two lambda where the attributes have identical keys" do
        before do
          klass.map "attribute", "attribute", ->(v) { v.downcase }, ->(v) { v.upcase }
        end


        context "with attributes matching the left key" do
          it "maps the left key to the right key, using the first lambda to map the value" do
            mapping = klass.new("attribute" => "Value").mapped_attributes
            expect(mapping['attribute']).to eq 'value'
          end

          it "maps the right key to the left key, using the second lambda to map the value" do
            mapping = klass.new("attribute" => "Value").unmapped_attributes
            expect(mapping['attribute']).to eq 'VALUE'
          end
        end
      end

      context "and two lambda where the attributes have identical keys but map different types" do
        before do
          klass.map "attribute", "attribute", ->(v) { v.split('') }, ->(v) { v.join('') }
        end

        context "with attributes matching the left key" do
          it "maps the left key to the right key, using the first lambda to map the value" do
            mapping = klass.new("attribute" => "Va").mapped_attributes
            expect(mapping['attribute']).to eq(['V', 'a'])
          end

          it "maps the right key to the left key, using the second lambda to map the value" do
            mapping = klass.new("attribute" => ["V", "a"]).unmapped_attributes
            expect(mapping['attribute']).to eq 'Va'
          end
        end
      end
    end

    context "with an array" do
      let(:attributes) { { "Attribute1" => "Value1", "Attribute2" => "Value2" } }

      context "and no lambda" do
        before { klass.map %w{ Attribute1 Attribute2 } }

        it 'remains the same' do
          mapping =  klass.new(attributes).mapped_attributes
          expect(mapping).to eq attributes
        end
      end

      context "and a 1-arity lambda" do
        before { klass.map %w{ Attribute1 Attribute2 }, ->(v) { v.downcase } }

        it 'maps the values using the passed lambda' do
          mapping =  klass.new(attributes).mapped_attributes
          expected_mapping = { "Attribute1" => "value1", "Attribute2" => "value2" }
          expect(mapping).to eq expected_mapping
        end
      end

      context "and a 2-arity lambda" do
        before do
          klass.map %w{ Attribute1 Attribute2 }, ->(k,v) { [k.downcase, v.downcase] }
        end

        it 'maps both keys and values using the lambda' do
          mapping =  klass.new(attributes).mapped_attributes
          expected_mapping = { "attribute1" => "value1", "attribute2" => "value2" }
          expect(mapping).to eq expected_mapping
        end
      end
    end
  end
end
