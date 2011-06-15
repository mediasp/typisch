module Typisch
  class Type::String < Type::Constructor::Singleton
    def self.tag
      "String"
    end

    def check_type(instance)
      ::String === instance
    end

    Registry.register_global_type(:string, top_type)
  end
end
