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
    it "should allow either syntax: <type>.union(other) or Type::Union.union(type, other)" do
      assert_equal \
        Type::Union.union(Type::BOOLEAN, Type::INTEGRAL),
        Type::BOOLEAN.union(Type::INTEGRAL)
    end

    it "should happily keep distinct unions of types of different Type::Tagged subclasses" do
      union = Type::Union.union(Type::BOOLEAN, Type::INTEGRAL)
      assert_equal 2, union.alternative_types.length
      assert union.alternative_types.include?(Type::BOOLEAN)
      assert union.alternative_types.include?(Type::INTEGRAL)
    end
    
    it "should not be sensitive to ordering when doing comparisons" do
      assert_equal \
        Type::Union.union(Type::BOOLEAN, Type::INTEGRAL),
        Type::Union.union(Type::INTEGRAL, Type::BOOLEAN)
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

    describe "when computing least upper bounds of different object types" do
      it "should take only slots present in all the object types in the union" do
        union = Type::Union.union(
          Type::Object.new('Object', :foo => Type::INTEGRAL, :bar => Type::BOOLEAN),
          Type::Object.new('Object', :boo => Type::INTEGRAL, :bar => Type::BOOLEAN)
        )
        assert_equal Type::Object.new('Object', :bar => Type::BOOLEAN), union
      end

      it "should recursively taking the union of the types in their shared slots" do
        union = Type::Union.union(
          Type::Object.new('Object', :foo => Type::INTEGRAL, :bar => Type::BOOLEAN),
          Type::Object.new('Object', :boo => Type::INTEGRAL, :bar => Type::NULL)
        )
        assert_equal Type::Object.new('Object', :bar => Type::Union.union(Type::BOOLEAN, Type::NULL)), union
      end

      it "should leave separate clauses in the union where their type tags are non-overlapping" do
        union = Type::Union.union(
          Type::Object.new('TestClass'),
          Type::Object.new('TestClass2')
        )
        assert_equal 2, union.alternative_types.length
      end

      it "should, when type tags have a common upper bound amongst them, pick the right upper bound" do
        union = Type::Union.union(
          Type::Object.new('TestSubclass'),
          Type::Object.new('TestClass')
        )
        assert_equal 1, union.alternative_types.length
        assert_equal 'TestClass', union.alternative_types[0].tag
        
        union = Type::Union.union(
          Type::Object.new('TestClass'),
          Type::Object.new('TestSubclass')
        )
        assert_equal 1, union.alternative_types.length
        assert_equal 'TestClass', union.alternative_types[0].tag
        
        union = Type::Union.union(
          Type::Object.new('TestClass2'),
          Type::Object.new('TestSubclass'),
          Type::Object.new('TestModule')
        )
        assert_equal 1, union.alternative_types.length
        assert_equal 'TestModule', union.alternative_types[0].tag
      end
      
      it "should group types into separate union clauses by their upper bounds when there are non-overlapping groups some of which can be unified" do
        union = Type::Union.union(
          # one group
          Type::Object.new('TestClass2'),
          # another
          Type::Object.new('TestClass'),
          Type::Object.new('TestSubclass')
        )
        assert_equal 2, union.alternative_types.length
        assert_includes union.alternative_types, Type::Object.new('TestClass2')
        assert_includes union.alternative_types, Type::Object.new('TestClass')
      end

      it "should unify properties within these groups but leave differences in properties intact across these groups" do
        union = Type::Union.union(
          Type::Object.new('TestClass2', :baz => Type::STRING),
          
          Type::Object.new('TestClass', :foo => Type::BOOLEAN, :bar => Type::BOOLEAN),
          Type::Object.new('TestSubclass', :foo => Type::NULL, :baz => Type::BOOLEAN)
        )
        assert_equal 2, union.alternative_types.length
        assert_includes union.alternative_types, Type::Object.new('TestClass',
          :foo => Type::Union.union(Type::BOOLEAN, Type::NULL)
        )
        assert_includes union.alternative_types, Type::Object.new('TestClass2', 
          :baz => Type::STRING
        )
      end
    end


  end
end