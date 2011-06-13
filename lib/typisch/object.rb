class Typisch::Type
  class Object < Tagged
    class << self
      def top_type(*)
        new("Object")
      end
              
      def subgoals_to_prove_subtype(x, y)
        return false unless x.class_or_module <= y.class_or_module
        y.property_names_to_types.map do |y_propname, y_type|
          x_type = x[y_propname] or return false
          [x_type, y_type]
        end
      end
      
      # the object types in the union are guaranteed to have non-overlapping
      # class_or_module's, as we chose them that way; so, we can find (zero or)
      # one of them uniquely to test as a possible supertype of some object
      # type x.
      def pick_subtype_goal_from_alternatives_in_union(x, alternative_ys)
        y_choice = alternative_ys.find {|y| x.class_or_module <= y.class_or_module}
        y_choice && [x, y_choice]
      end
      
      def least_upper_bounds_for_union(*objects)
        groups_by_upper_bound = []
        objects.each do |object|
          # this needs a cleanup, essentially we're forming clusters of comparable items
          # within a poset
          
          dominated, rest = groups_by_upper_bound.partition do |bound, group|
            bound <= object.class_or_module
          end
          dominating, rest = rest.partition do |bound, group|
            object.class_or_module <= bound
          end
          if dominating.length > 1
            raise "todo handle overlapping case"
          end
          new_bound = if dominating.length == 1
            dominating.first.first
          else
            object.class_or_module
          end
          
          merged_group = (dominated + dominating).map {|bound,group| group}.flatten
          merged_group << object
          rest << [new_bound, merged_group]
          groups_by_upper_bound = rest
        end
        # todo: what if the groups overlap?
        groups_by_upper_bound.map do |bound, group|
          union_properties(bound.to_s, group)
        end
      end
      
      def union_properties(tag, objects)
        # first we figure out which properties they all have in common:
        shared_property_names = objects.map(&:property_names).inject(:&)
        
        # then union these:
        properties = {}
        shared_property_names.each do |name|
          properties[name] = Type::Union.union(*objects.map {|o| o[name]})
        end
        new(tag, properties)
      end

      # partitions into non-overlapping
      def ruby_modules_non_overlapping_least_upper_bounds(*modules)
        lubs = []
        modules.each do |mod|
          next if lubs.any? {|lub| mod <= lub}
          found = groups.find {|g| !g.any? {|elem| ruby_modules_overlap?(elem, mod)}}
          if found
            found << mod
          else
            groups << [mod]
          end
        end
      end
      
      # Finds the least upper bound of two ruby classes or modules.
      # eg
      # > ruby_modules_least_upper_bound(Fixnum, Float)
      #  => Precision
      # 
      # Looks for the first class or module which appears in all the ancestors
      # arrays. In the case of modules, there may not be any common 'ancestor'
      # so we just return Object, since everything's guaranteed to be one of
      # those.
      def ruby_modules_least_upper_bound(*modules)
        # there's no special 'Nothing' class in ruby 
        return if modules.empty?

        ancestors = modules.map(&:ancestors).flatten(1)
        counts = Hash.new(0)
        ancestors.each do |a|
          counts[a] += 1
          return a if counts[a] == modules.length
        end
        return ::Object
      end
      
      # Finds out whether or not the two modules 'overlap'.
      # If these are two Classes the question is easy to settle,
      # either one of them is a subclass of the other, or no.
      #
      # If one of them is a module, though, it's actually rather
      # a pain to find out, we may have to traverse every
      # defined module/class looking for any which include/subclass
      # both proposed parents.
      #
      # Note: it would be nice if we could find a greatest lower
      # bound, but in case of modules this may not exist even in
      # cases of overlap there may be multiple equally-valid maximal
      # lower bounds.
      def ruby_modules_overlap?(mod1, mod2)
        # one is a subclass of or includes the other. obvious overlap.
        return true if mod1 <= mod2 || mod2 <= mod1

        # two classes which aren't subclasses of eachother: no overlap
        return false if mod1.is_a?(::Class) && mod2.is_a?(::Class)

        # One of them is a Module. I don't think there's
        # actually any quicker way than this to find out the
        # first class or module which includes them all:
        ObjectSpace.each_object(::Module) do |candidate|
          return true if candidate <= mod1 && candidate <= mod2
        end
        return false
      end
      
    end

    def initialize(tag, property_names_to_types={})
      @tag = tag
      raise "expected String tag name for first argument" unless tag.is_a?(::String)
      @property_names_to_types = property_names_to_types
    end

    attr_reader :tag, :property_names_to_types

    def class_or_module
      tag.split('::').inject(::Object) {|a,b| a.const_get(b)}
    end

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