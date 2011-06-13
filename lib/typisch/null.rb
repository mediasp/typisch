module Typisch
  class Type::Null < Type::Tagged::Singleton
    def self.tag
      "Null"
    end

    Registry.register_global_type(:null, top_type)
    Type::Tagged::RESERVED_TAGS << tag
  end
end
