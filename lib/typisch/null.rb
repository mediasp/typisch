module Typisch
  class Type::Null < Type::Tagged::Singleton
    def self.tag
      "Null"
    end

    Type::NULL = top_type
    Type::Tagged::RESERVED_TAGS << tag
  end
end