module Typisch
  class Type::Boolean < Type::Constructor::Singleton
    def self.tag
      "Boolean"
    end

    Registry.register_global_type(:boolean, top_type)
    Type::Constructor::RESERVED_TAGS << tag
  end
end
