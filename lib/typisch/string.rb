module Typisch
  class Type::String < Type::Tagged::Singleton
    def self.tag
      "String"
    end

    Type::STRING = top_type
    Type::Tagged::RESERVED_TAGS << tag
  end
end