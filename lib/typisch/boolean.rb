module Typisch
  class Type::Boolean < Type::Constructor::Singleton
    def self.tag
      "Boolean"
    end

    Registry.register_global_type(:boolean, top_type)
  end
end
