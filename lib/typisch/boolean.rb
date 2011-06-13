module Typisch
  class Type::Boolean < Type::Tagged::Singleton
    def self.tag
      "Boolean"
    end

    Registry.register_global_type(:boolean, top_type)
    Type::Tagged::RESERVED_TAGS << tag
  end
end
