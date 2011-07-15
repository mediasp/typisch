module Typisch
  class Type::Union < Type
    attr_reader :alternative_types
    alias :subexpression_types :alternative_types

    def initialize(*alternative_types)
      @alternative_types = alternative_types
    end

    def check_type(instance, &recursively_check_type)
      type = @alternative_types.find {|t| t.shallow_check_type(instance)}
      type && recursively_check_type[type, instance]
    end

    def shallow_check_type(instance)
      @alternative_types.any? {|t| t.shallow_check_type(instance)}
    end

    def excluding_null
      types = @alternative_types.reject {|t| Type::Null === t}
      types.length == 1 ? types.first : Type::Union.new(*types)
    end

    def canonicalize!
      @alternative_types.map!(&:target)

      unless @alternative_types.all? {|t| Type::Constructor === t} &&
             (tags = @alternative_types.map(&:tag)).uniq.length == tags.length
        raise TypeDeclarationError, "the types in a Union must be constructor types with different tags"
      end
    end

    def to_string(depth, indent)
      next_indent = "#{indent}  "
      types = @alternative_types.map {|t| t.to_s(depth+1, next_indent)}
      "union(\n#{next_indent}#{types.join(",\n#{next_indent}")}\n#{indent})"
    end

  end

  # The Nothing (or 'bottom') type is just an empty Union:
  class Type::Nothing < Type::Union
    def initialize
      super
    end

    def to_s(*); @name.inspect; end

    INSTANCE = new
    class << self; private :new; end
    Registry.register_global_type(:nothing, INSTANCE)
  end

  # The Any (or 'top') type is just a union of all the top types of the various Type::Constructor
  # subclasses:
  class Type::Any < Type::Union
    def initialize
      super(*Type::LATTICES.map {|lattice| lattice.top_type(self)})
    end

    def to_s(*); @name.inspect; end

    def canonicalize!; end

    # skip some unnecessary work checking different alternatives, since we know everything
    # works here:
    def check_type(instance)
      true
    end

    INSTANCE = new
    class << self; private :new; end
    Registry.register_global_type(:any, INSTANCE)
  end
end
