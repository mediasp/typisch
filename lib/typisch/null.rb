module Typisch
  class Type::Null < Type::Constructor::Singleton
    def self.tag
      "Null"
    end

    Registry.register_global_type(:null, top_type)
    Type::Constructor::RESERVED_TAGS << tag
  end
end
