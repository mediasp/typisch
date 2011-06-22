# TODO: have this work with whichever of these classes
# end up getting required, without having to require them
# upfront
require 'rational'
require 'bigdecimal'
require 'complex'

module Typisch
  # This is aiming to be a nice numeric tower like those of Scheme etc:
  #   Integral < Rational < Real < Complex
  #
  # In these kinds of numeric tower, type and degree of precision is treated as a separate
  # orthogonal concern; for now I've not treated precision at all here, although
  # support could be added, eg to allow a distinction between
  #  - fixed precision binary floating point (Float)
  #  - arbitrary precision decimal floating point (BigDecimal)
  #  - fixed size integer (Fixnum)
  #  - arbitrary size integer (Bignum)
  #  - etc
  # There are quite a few ways to classify numeric types, so I've stuck with just the
  # most basic mathematical numeric tower classification for now.
  class Type::Numeric < Type::Constructor

    def initialize(type, *valid_implementation_classes)
      @type = type
      @valid_implementation_classes = valid_implementation_classes
    end

    attr_reader :valid_implementation_classes

    # Note: these are based on how ruby 1.8.7 does it; 1.9 changes
    # things slightly IIRC so may need tweaks to cope with this.
    # Either way ruby's hierarchy of numeric types is slightly idiosyncratic:
    complex  = new('Complex',  ::Numeric)
    real     = new('Real',     ::Precision, ::BigDecimal, ::Rational)
    rational = new('Rational', ::Rational, ::Integer)
    integral = new('Integral', ::Integer)

    Registry.register_global_type(:complex, complex)

    Registry.register_global_type(:real, real)
    Registry.register_global_type(:float, real) # aliasing this as :float too

    Registry.register_global_type(:rational, rational)

    Registry.register_global_type(:integral, integral)
    Registry.register_global_type(:integer, integral)  # aliasing this as :integer too

    TOWER = [complex, real, rational, integral]

    class << self
      private :new

      def top_type(*)
        TOWER.first
      end

      def check_subtype(x, y)
        x.index_in_tower >= y.index_in_tower
      end
    end

    def to_s(*)
      @name.inspect
    end

    def tag
      @type
    end

    def index_in_tower
      TOWER.index {|t| t.equal?(self)}
    end

    def shallow_check_type(instance)
      case instance when *@valid_implementation_classes then true else false end
    end
    alias :check_type :shallow_check_type

    def subexpression_types
      []
    end
  end
end
