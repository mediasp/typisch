require 'date'
require 'time'

module Typisch
  class Type::Date < Type::Constructor::Singleton
    def self.tag; "Date"; end
    Registry.register_global_type(:date, top_type)

    # You could add your own to the list, if you have some alternative ruby implementation
    # with a Date-like interface which you want to typecheck.
    VALID_IMPLEMENTATION_CLASSES = [::Date]

    def check_type(instance)
      case instance when *VALID_IMPLEMENTATION_CLASSES then true else false end
    end
  end

  class Type::Time < Type::Constructor::Singleton
    def self.tag; "Time"; end
    Registry.register_global_type(:datetime, top_type)
    Registry.register_global_type(:time, top_type)

    # You could add your own to the list, if you have some alternative ruby implementation
    # with a Time-like interface which you want to typecheck here.
    #
    # Maybe allow DateTime too under ruby? its interface is slightly different though.
    # Typisch types are aiming to not be overly coupled to the structure of implementation
    # classes in Ruby though - eg when serializing to JSON we don't really care about
    # ruby's DateTime vs Time quirks. So, not sure whether to add DateTime here and pretend
    # its interface is similar enough to that of Time, or just pretend it doesn't exist.
    #
    # Or maybe we could just define this as 'anything which respond_to?(:to_time)' or similar.
    # Although annoyingly DateTime and Time don't even have to_time / to_datetime methods to
    # convert between them. Poor stdlib design :(
    VALID_IMPLEMENTATION_CLASSES = [::Time]

    def check_type(instance)
      case instance when *VALID_IMPLEMENTATION_CLASSES then true else false end
    end
  end
end
