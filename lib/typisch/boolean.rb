module Typisch
  class Type::Boolean < Type::Tagged::Singleton
    def self.tag
      "Boolean"
    end

    Type::BOOLEAN = top_type
    Type::Tagged::RESERVED_TAGS << tag
  end
end