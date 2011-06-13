module Typisch
  class Type::String < Type::Tagged::Singleton
    def self.tag
      "String"
    end

    Registry.register_global_type(:string, top_type)
    Type::Tagged::RESERVED_TAGS << tag
  end
end
