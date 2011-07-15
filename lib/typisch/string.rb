module Typisch
  # String types support refinement types, specifying a set of allowed values,
  # or a maximum length.
  #
  # About ruby Symbols: these are a pain in the arse.
  # For now I'm allowing them to type-check interchangably with Strings.
  # Since Typisch isn't specifically designed for Ruby's quirks but for more general
  # data interchange, I don't think Symbol should have a special priviledged type
  # of its own.
  #
  # Nevertheless if we ever allow custom type tags on String types (as we do for
  # Object types at the moment) we could perhaps allow Symbol as a specially-tagged psuedo
  # string like type. Although it's not a subclass of String, so hmm.
  class Type::String < Type::Constructor
    class << self
      def tag
        "String"
      end

      def top_type(*)
        @top_type ||= new
      end

      def check_subtype(x, y)
        x.equal?(y) || (
          (x.max_length || Infinity) <= (y.max_length || Infinity) &&
          (!y.values || (x.values && (x.values & y.values).length == x.values.length))
        )
      end
    end
    Type::LATTICES << self

    def initialize(refinements={})
      @refinements = refinements
    end

    Infinity = 1.0/0

    def max_length
      @refinements[:max_length]
    end

    def values
      @refinements[:values]
    end

    def tag
      self.class.tag
    end

    def to_s(*)
      @name ? @name.inspect : "string(#{@refinements.inspect})"
    end

    def self.tag
      "String"
    end

    def shallow_check_type(instance)
      (::String === instance || ::Symbol === instance) &&
      (!values     || values.include?(instance.to_s)) &&
      (!max_length || instance.to_s.length <= max_length)
    end

    Registry.register_global_type(:string, top_type)
  end
end
