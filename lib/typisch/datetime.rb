module Typisch
  class Type::Date < Type::Constructor::Singleton
    def self.tag; "Date"; end
    Registry.register_global_type(:date, top_type)
  end

  class Type::Time < Type::Constructor::Singleton
    def self.tag; "Time"; end
    Registry.register_global_type(:datetime, top_type)
    Registry.register_global_type(:time, top_type)
  end
end
