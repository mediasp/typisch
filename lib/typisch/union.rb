class Typisch::Type
  class Union < self
    attr_reader :alternative_tagged_types, :alternative_types_by_tag

    class << self
      private :new
      def union(*types)
        return Bottom.new if types.length == 0
        return types.first if types.length == 1
        
        # todo check non-overlapping
        # push down unions in overlapping cases
        
        Union.new(*types)
      end
    end

    def initialize(*types)
      @alternative_tagged_types = types
      @alternative_types_by_tag = {}
      types.each do |type|
        @alternative_types_by_tag[type.tag] = type
      end
    end

    def to_s
      @alternative_tagged_types.join(' | ')
    end
  end
  
  # The bottom type is just an empty Union type:
  class Bottom < Union
    def initialize
      super()
    end
    
    def to_s
      "Bottom"
    end
  end
  
  # The top type is just a union of all the top types of the various Type::Tagged
  # subclasses:
  class Top < Union
    def initialize
      top_tagged_types = Tagged::TAGGED_TYPE_SUBCLASSES.map {|klass| klass.top_type(self)}
      super(*top_tagged_types)
    end
    
    def to_s
      "Top"
    end
  end
end