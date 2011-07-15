class Typisch::Type
  # A Sequence is an ordered collection of items, all of a given type.
  #
  # For now if you want an unordered collection, you just have to treat it
  # as an ordered collection with arbitrary order; if you want a map/hash you
  # just treat it as a sequence of tuples. TODO: would be nice to
  # have more of a hierarchy of collection types here, eg OrderedSequence < Set.
  #
  #
  # (ordered) Sequences support 'slice types', which are a kind of structural
  # supertype for sequences. Their use is primarily in specifying partial
  # serializations or partial type-checking for large sequences.
  #
  # Eg sequence(:integer, :slice => 0...10)
  #
  # This is saying: "A sequence of ints, which may be of any known length, but
  # where I only care (to validate, serialize, ...) at most the first 10 items".
  #
  # Eg sequence(:integer, :slice => 0...10, :total_length => false)
  #
  # This is saying: "A sequence of ints, which may be of any known or unknown length,
  # but where I only care about (validating, serializing, ...) at most the first 10 items,
  # and I don't care about (validating, serializing...) the total length of the collection
  class Sequence < Constructor
    class << self
      def top_type(overall_top)
        new(overall_top, :slice => (0...0), :total_length => false)
      end

      def check_subtype(x, y, &recursively_check_subtype)
        recursively_check_subtype[x.type, y.type] && (
          !x.slice ||
          (y.slice && (
            x.slice.begin <= y.slice.begin &&
            x.slice.end >= y.slice.end &&
            (x.total_length || !y.total_length)
          ))
        )
      end
    end
    LATTICES << self

    def initialize(type, options={})
      @type = type
      if options[:slice]
        @slice = options[:slice]
        @slice = (@slice.begin...@slice.end+1) unless @slice.exclude_end?
        @total_length = options[:total_length] != false
      end
    end

    attr_reader :slice, :total_length

    def with_options(options)
      Sequence.new(@type, {:slice => @slice, :total_length => @total_length}.merge!(options))
    end

    def subexpression_types
      [@type]
    end

    def check_type(instance, &recursively_check_type)
      shallow_check_type(instance) && if @slice
        (instance[@slice] || []).all? {|i| recursively_check_type[@type, i]} &&
        (!@total_length || ::Integer === instance.length)
      else
        instance.all? {|i| recursively_check_type[@type, i]}
      end
    end

    # I tried allowing any Enumerable, but this resulted in allowing String and a bunch
    # of other things which sort of expose a vaguely-array-like interface but not really
    # in a way that's helpful for typing purposes. E.g. String in 1.8.7 exposes Enumerable
    # over its *lines*, but an array-like interface over its *characters*, sometimes as
    # strings, sometimes as ascii char codes. So not consistent at all.
    #
    # Any other classes added here must expose Enumerable, but also .length and slices
    # via [] (at least if you want them to work with slice types).
    #
    # For now allowing Hashes too so they can be typed as a sequence of tuples, although should
    # really only be typed as a set of tuples as there's no ordering or support for slices.
    VALID_IMPLEMENTATION_CLASSES = [::Array, ::Hash]

    def shallow_check_type(instance)
      case instance when *VALID_IMPLEMENTATION_CLASSES then true else false end
    end

    def tag
      "Sequence"
    end

    attr_reader :type

    def to_string(depth, indent)
      result = "sequence(#{@type.to_s(depth+1, indent)}"
      if @slice
        result << ", :slice => #{@slice}"
        result << ", :total_length => false" unless @total_length
      end
      result << ")"
    end

    def canonicalize!
      @type = @type.target
    end
  end

  class Map < Sequence
    def type_lattice; Sequence; end

    def initialize(key_type, value_type)
      super(Tuple.new(key_type, value_type))
    end

    def key_type;   @type[0]; end
    def value_type; @type[1]; end

    def to_string(depth, indent)
      next_indent = "#{indent}  "
      result = "map(\n#{next_indent}"
      result << @type[0].to_s(depth+1, next_indent)
      result << "\n#{next_indent}"
      result << @type[1].to_s(depth+1, next_indent)
      result << "\n#{indent})"
    end
  end

end
