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
    self.class.subtype?(self, other)
  end

  def <(other)
    self <= other && !(self >= other)
  end

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
    (other <= self ? 1 : 0) - (self <= other ? 1 : 0)
  end

  def inspect
    "#<#{self.class} #{to_s}>"
  end

  def to_s
    raise NotImplementedError
  end

  # For convenience. Type::Tagged will implement this as [self], whereas
  # Type::Union will implement it as its full list of alternative tagged types.
  def alternative_tagged_types
    raise NotImplementedError
  end
  
  def alternative_types_by_tag
    raise NotImplementedError
  end
end