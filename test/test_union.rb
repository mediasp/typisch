require 'test/common'

describe "Union types" do
  describe "Nothing" do

    it "is the overall bottom type: a subtype of anything one cares to shake a stick at" do
      [
        Type::ANY,
        Type::BOOLEAN,
        Type::NULL,
        Type::COMPLEX,
        Type::REAL,
        Type::RATIONAL,
        Type::INTEGRAL,
        Type::Sequence.new(Type::BOOLEAN),
        Type::Tuple.new(Type::BOOLEAN, Type::REAL),
        Type::Object.new('Object', :foo => Type::BOOLEAN)
      ].each do |t|
        assert_operator Type::NOTHING, :<, t
      end
      
      assert_operator Type::NOTHING, :<=, Type::NOTHING
      refute_operator Type::ANY, :<= ,Type::NOTHING
    end

  end

  describe "Any" do
    it "is the overall top type: a supertype of anything one cares to shake a stick at" do
      [
        Type::BOOLEAN,
        Type::NULL,
        Type::COMPLEX,
        Type::REAL,
        Type::RATIONAL,
        Type::INTEGRAL,
        Type::Sequence.new(Type::BOOLEAN),
        Type::Sequence.new(Type::ANY),
        Type::Tuple.new(Type::BOOLEAN, Type::REAL, Type::ANY),
        Type::Object.new('Object', :foo => Type::BOOLEAN),
        Type::NOTHING
      ].each do |t|
        assert_operator t, :<, Type::ANY
      end
      
      assert_operator Type::ANY, :<=, Type::ANY
      refute_operator Type::NOTHING, :>= ,Type::ANY
    end
  end
  
  describe "union" do
    it "should happily keep distinct unions of types of different Type::Tagged subclasses" do
      union = Type::Union.union(Type::BOOLEAN, Type::INTEGRAL)
      assert_equal 2, union.alternative_types.length
      assert union.alternative_types.include?(Type::BOOLEAN)
      assert union.alternative_types.include?(Type::INTEGRAL)
    end
    
    it "should return the NOTHING type for an empty union" do
      assert_equal Type::NOTHING, Type::Union.union()
    end
    
    it "should not wrap a single clause in a Union, just return it as-is" do
      assert_equal Type::BOOLEAN, Type::Union.union(Type::BOOLEAN)
    end

    it "should flatten out any nested union passed to it" do
      union = Type::Union.union(Type::BOOLEAN, Type::INTEGRAL)
      union = Type::Union.union(union, Type::NULL)
      assert_equal 3, union.alternative_types.length
      assert union.alternative_types.include?(Type::BOOLEAN)
      assert union.alternative_types.include?(Type::INTEGRAL)
      assert union.alternative_types.include?(Type::NULL)
    end
    
    it "should pick the least upper bound of numeric types rather than leave them in separate overlapping union clauses" do
      assert_equal Type::REAL, Type::Union.union(Type::REAL, Type::INTEGRAL)
      assert_equal Type::COMPLEX, Type::Union.union(Type::RATIONAL, Type::COMPLEX)
    end

    it "should eliminate duplicates (and using type equality not just instance equality)" do
      assert_equal Type::COMPLEX, Type::Union.union(Type::COMPLEX, Type::COMPLEX)

      assert_equal Type::Union.union(Type::COMPLEX, Type::NULL), Type::Union.union(Type::COMPLEX, Type::COMPLEX, Type::NULL)
      assert_equal 2, Type::Union.union(Type::COMPLEX, Type::COMPLEX, Type::NULL).alternative_types.length

      # uses type equality
      assert_equal Type::Sequence.new(Type::BOOLEAN), Type::Union.union(Type::Sequence.new(Type::BOOLEAN), Type::Sequence.new(Type::BOOLEAN))
    end
    
    it "should compute least upper bounds of different sequence types via recursively taking the union of their parameter types" do
      seq_union = Type::Union.union(Type::Sequence.new(Type::BOOLEAN), Type::Sequence.new(Type::NULL))
      assert_equal Type::Sequence.new(Type::Union.union(Type::BOOLEAN, Type::NULL)), seq_union
    end

    it "should compute least upper bounds of different tuple types via recursively taking the union of their types slot-wise" do
      tup_union = Type::Union.union(Type::Tuple.new(Type::BOOLEAN, Type::INTEGRAL), Type::Tuple.new(Type::NULL, Type::REAL))
      assert_equal Type::Tuple.new(Type::Union.union(Type::BOOLEAN, Type::NULL), Type::REAL), tup_union
    end

  end
end