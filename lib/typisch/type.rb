# Base class for types, with some convenience methods.
#
# Note: since most of the algorithms on types (subtyping, union, intersection, ...)
# operate on pairs of types, we don't use methods on the actual type subclasses very much,
# since polymorphic dispatch on just one of the pair of types isn't much use in terms
# of extensibility.
#
# Instead the actual Type classes themselves are kept fairly lightweight, with the algorithms
# implemented separately in class methods.
class Typisch::Type
  def <=(other)
    Typisch::Type.subtype?(self, other)
  end

  def <(other)
    self <= other && !(self >= other)
  end

  # N.B. equality is based on the subtyping algorithm. So, we cannot rely on
  # using == on types inside any methods used in the subtyping algorithm.
  # We must rely only on .equal? instance equality instead.
  #
  # Note that we have *not* overridden hash and eql? to be compatible with
  # this subtyping-based equality, since it's not easy to find a unique
  # representative of the equivalence class on which to base a hash function.
  #
  # This means that hash lookup of types will remain based on instance
  # equality, and can safely be used inside the subtyping logic without
  # busting the stack
  def ==(other)
    self <= other && self >= other
  end

  def >=(other)
    other <= self
  end

  def >(other)
    other < self
  end

  def <=>(other)
    if other <= self
      self <= other ? 0 : 1
    else
      self <= other ? -1 : nil
    end
  end

  # Union and intersection

  def union(*others)
    Union.new(self, *others)
  end
  alias :| :union

  def intersection(*others)
    Interesction.intersection(self, *others)
  end
  alias :& :intersection


  def inspect
    "#<Type: #{to_s}>"
  end

  # overridden on the Placeholder proxy wrapper, otherwise points at self
  def target; self; end

  def to_s(depth=0, indent='')
    return @name.inspect if depth > 0 && @name
    return "..." if depth > 3 # MAX_DEPTH
    to_string(depth, indent)
  end

  def to_string(depth, indent)
    raise NotImplementedError
  end

  attr_reader :name
  def name=(name)
    raise "name already set" if @name
    @name = name
  end
  private :name=

  # types may be annotated with a hash of arbitrary stuff.
  # could use this to document them, or to add instructions for
  # other tools which do type-directed metaprogramming.

  def annotations
    @annotations ||= {}
  end

  def annotations=(annotations)
    @annotations = annotations
  end

  # For convenience. Type::Constructor will implement this as [self], whereas
  # Type::Union will implement it as its full list of alternative constructor types.
  def alternative_types
    raise NotImplementedError
  end

  # should return a list of any subexpressions which are themselves types.
  # used by any generic type-graph-traversing logic.
  def subexpression_types
    raise NotImplementedError
  end

  # Does this type make any use of recursion / is it an 'infinite' type?
  def recursive?(found_so_far={})
    found_so_far[self] or begin
      found_so_far[self] = true
      result = subexpression_types.any? {|t| t.recursive?(found_so_far)}
#      subexpression_types.each {|t| raise t.inspect if t.recursive?(found_so_far)}
      found_so_far.delete(self)
      result
    end
  end

  # This may be called to canonicalize the type graph starting at this type.
  # it should always return something == to self.
  #
  # Before calling canonicalize recursively on other child types, it needs to
  # first check in the existing_canonicalizations map.
  # It should also add the mapping for self into this map and pass it on
  # down the call graph if it does call canonicalize on child types.
  # This is so it can work in a possibly-cyclic graph setting, as per the
  # various other coinductive/corecursive algorithms we have for types.
  # (unlike with subtyping though, we don't at present backtrack during
  # canonicalization).
  def canonicalize(existing_canonicalizations=nil, recursion_unsafe=nil)
    self
  end

  # should check the type of this instance, but only 'one level deep', ie
  # typically just check its type tag without recursively type-checking
  # any child objects.
  def shallow_check_type(instance)
    raise NotImplementedError
  end

  # returns a version of this type which excludes null.
  # generally will be self, except when a union type which includes null.
  def excluding_null
    self
  end

private

  # Inidividual type subclasses must implement this. If they need to
  # perform some recursive typecheck, eg on child objects of the object
  # they're validating, they should call the supplied recursively_check_type
  # block to do so, rather than calling === directly.
  def check_type(instance, &recursively_check_type)
    raise NotImplementedError
  end

end
