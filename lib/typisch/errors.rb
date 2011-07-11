module Typisch
  class Error < StandardError; end
  class TypeDeclarationError < Error; end
  class NameResolutionError < TypeDeclarationError
    def initialize(type_name)
      super("Problem resolving named placeholder type: cannot find type with name #{type_name} in registry")
    end
  end
  class SerializationError < Error; end
  class CyclicSerialization < SerializationError; end
end
