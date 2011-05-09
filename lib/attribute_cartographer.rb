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
      block = (Proc === args.last) ? args.pop : ->(v) { v }

      raise AttributeCartographer::InvalidArgumentError if block.arity > 1

      if Array === args.first
        raise AttributeCartographer::InvalidArgumentError if args.first.empty?
        args.first.each { |arg| @mapper.merge! arg => [arg, block] }
      else
        from, to = args
        to = from unless to
        @mapper.merge! from => [to, block]
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
