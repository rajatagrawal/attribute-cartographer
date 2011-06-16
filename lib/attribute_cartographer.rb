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

      passthrough = ->(v) { v }
      f1 ||= passthrough
      f2 ||= passthrough

      if Array === from
        if f1.arity == 1
          from.each { |k| @mapper[k] = [k, f1] }
        else
          from.each { |k| @mapper[k] = f1 }
        end
      else
        raise AttributeCartographer::InvalidArgumentError if to && f1.arity == 2

        @mapper[from] = (f1.arity == 1 ? [to || from, f1] : f1)
        @mapper[to] = [from, f2] if to && (f1 == f2 || f2 != passthrough)
      end
    end
  end

  module InstanceMethods
    def initialize attributes = {}
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
      return unless mapper

      (mapper.keys & attributes.keys).each do |key|
        mapping = mapper[key]

        if Array === mapping
          mapped_key, f = mapping
          value = f.call(attributes[key])
        else
          mapped_key, value = mapping.call(key, attributes[key])
        end

        @_mapped_attributes[mapped_key] = value
      end
    end
  end
end
