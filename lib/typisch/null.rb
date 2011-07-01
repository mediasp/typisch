module Typisch
  class Type::Null < Type::Constructor::Singleton
    def self.tag
      "Null"
    end

    def shallow_check_type(instance)
      instance.nil?
    end

    def excluding_null
      Type::Nothing::INSTANCE
    end

    Registry.register_global_type(:null, top_type)
  end
end
