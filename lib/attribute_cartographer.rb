module AttributeCartographer
  class InvalidArgumentError < StandardError; end

  class << self
    def included base
      base.send :extend, AttributeCartographer::ClassMethods
      base.send :include, AttributeCartographer::InstanceMethods
    end
  end

  module ClassMethods
    def map *args
      @mapper ||= {}

      (from, to), (f1, f2) = args.partition { |a| !(Proc === a) }

      raise AttributeCartographer::InvalidArgumentError if [f1,f2].compact.any? { |f| f.arity > 1 }

      f1 ||= ->(v) { v }
      to ||= from

      if Array === from
        from.each { |key| @mapper.merge! key => [key, f1] }
      else
        @mapper.merge! from => [to, f1]
        @mapper.merge! to => [from, f2] if f2
      end
    end
  end

  module InstanceMethods
    def initialize attributes
      @_original_attributes = attributes
      @_mapped_attributes = {}

      map_attributes! attributes

      super
    end

    def original_attributes
      @_original_attributes
    end

    def mapped_attributes
      @_mapped_attributes
    end

  private

    def map_attributes! attributes
      mapper = self.class.instance_variable_get(:@mapper)

      mapper.each { |original_key, (mapped_key, block)|
        value = attributes.has_key?(original_key) ? block.call(attributes[original_key]) : nil
        self.send :define_singleton_method, mapped_key, ->{ value }

        @_mapped_attributes.merge! mapped_key => value
      } if mapper
    end
  end
end
