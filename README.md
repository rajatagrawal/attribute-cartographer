# Attribute Cartographer

* http://github.com/krishicks/attribute-cartographer

### Description

Attribute Cartographer maps an attributes hash into similarly or differently named methods,
using an optional lambda to map the values as well.

### Installation

1.Install using gem,

`gem install attribute_cartographer`

2.For `bundler`, puts this in your Gemfile

  `gem 'attribute_cartographer'` and then `bundle`

### Usage

```
class Mapper
  include AttributeCartographer

  # ONE-WAY MAPPING

  # map a single key, value untouched
  map "UnchangedKey" 
  
  # same as above, but for multiple in a single statement
  map %w{ UnchangedKey1 UnchangedKey2 } 

  # maps the key, using the lambda for the value
  map "SameKeyNewValue", ->(v) { v.downcase }

  # same as above, but for multiple in a single statement
  map %w{ SameKeyNewValue1 SameKeyNewValue2 }, ->(v) { v.upcase }

  # maps the left key to the right key, using the lambda for the value
  map "OldKey", "new_key", ->(v) { v.downcase }

  # maps the key and value using the lambda for both
  map "DowncasedKeyAndValue", ->(k,v) { [k.downcase, v.downcase] }

  # same as the example above, but for multiple in a single statement
  map %w{ NewKeyAndValue1 NewKeyAndValue2 }, ->(k,v) { [k.downcase, v.downcase] }

  # TWO-WAY MAPPING

  # map the left key to the right key and vice-versa, value untouched
  map "AnotherOldKey", "another_new_key"

  # map the left key to the right key with the first lambda,
  # and the right key to the left key with the second lambda
  map "ThisKey", "to_this_key", ->(v) { v.downcase }, ->(v) { v.upcase }
end

Mapper.new("UnchangedKey" => "UnchangedValue", "OldKey" => "OldValue")`
```

### Module Methods
1. mapped_attributes method provides access to the mapped hash
2. original_attributes method provides access to the original hash
3. unmapped_attributes method provides access hash attributes which didn't have any mapping defined.

### Requirements

* Ruby 1.9.x

### License

MIT
