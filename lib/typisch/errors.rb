module Typisch
  class Error < StandardError; end
  class IllFormedRecursiveType < Error
    def initialize
      super("Encountered disallowed cyclic reference while canonicalizing type graph. Cyclic references must have a constructor type (Object,Tuple,Sequence etc) somewhere in the cycle")
    end
  end
  class NameResolutionError < Error
    def initialize(type_name)
      super("Problem resolving named placeholder type: cannot find type with name #{type_name} in registry")
    end
  end

end
