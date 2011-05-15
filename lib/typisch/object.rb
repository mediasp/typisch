class Typisch::Type
  class Object < Tagged
    class << self
      def top_tag
        "Object"
      end

      def subtag?(x, y)
        constantize(x) <= constantize(y)
      end
      
      def constantize(klass_name)
        klass_name.split('::').inject(::Object) {|a,b| a.const_get(b)}
      end
              
      def subgoals_to_prove_subtype(x, y)
        return false unless subtag?(x.tag, y.tag)
        y.property_names_to_types.map do |y_propname, y_type|
          x_type = x[y_propname] or return false
          [x_type, y_type]
        end
      end
    end

    def initialize(tag, property_names_to_types)
      @tag = tag
      @property_names_to_types = property_names_to_types
    end

    attr_reader :tag, :property_names_to_types

    def property_names
      @property_names_to_types.keys
    end

    def [](property_name)
      @property_names_to_types[property_name]
    end
    
    def to_s
      pairs = @property_names_to_types.map {|n,t| "#{n}: #{t}"}
      "#{@tag} {#{pairs.join(', ')}}"
    end
  end
end