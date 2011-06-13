require 'test/common'

describe "Union types" do
  before do
    @registry = Registry.new
    [:boolean, :null, :complex, :real, :rational, :integer, :any, :nothing].each do |t|
      instance_variable_set("@#{t}", @registry[t])
    end
  end

  describe "Nothing" do

    it "is the overall bottom type: a subtype of anything one cares to shake a stick at" do
      [
        @any,
        @boolean,
        @null,
        @complex,
        @real,
        @rational,
        @integer,
        Type::Sequence.new(@boolean),
        Type::Tuple.new(@boolean, @real),
        Type::Object.new('Object', :foo => @boolean)
      ].each do |t|
        assert_operator @nothing, :<, t
      end

      assert_operator @nothing, :<=, @nothing
      refute_operator @any, :<= ,@nothing
    end

  end

  describe "Any" do
    it "is the overall top type: a supertype of anything one cares to shake a stick at" do
      [
        @boolean,
        @null,
        @complex,
        @real,
        @rational,
        @integer,
        Type::Sequence.new(@boolean),
        Type::Sequence.new(@any),
        Type::Tuple.new(@boolean, @real, @any),
        Type::Object.new('Object', :foo => @boolean),
        @nothing
      ].each do |t|
        assert_operator t, :<, @any
      end

      assert_operator @any, :<=, @any
      refute_operator @nothing, :>= ,@any
    end
  end

  describe "union" do
    it "should allow either syntax: <type>.union(other) or Type::Union.union(type, other)" do
      assert_equal \
        Type::Union.union(@boolean, @integer),
        @boolean.union(@integer)
    end

    it "should happily keep distinct unions of types of different Type::Tagged subclasses" do
      union = Type::Union.union(@boolean, @integer)
      assert_equal 2, union.alternative_types.length
      assert union.alternative_types.include?(@boolean)
      assert union.alternative_types.include?(@integer)
    end

    it "should not be sensitive to ordering when doing comparisons" do
      assert_equal \
        Type::Union.union(@boolean, @integer),
        Type::Union.union(@integer, @boolean)
    end

    it "should return the NOTHING type for an empty union" do
      assert_equal @nothing, Type::Union.union()
    end

    it "should not wrap a single clause in a Union, just return it as-is" do
      assert_equal @boolean, Type::Union.union(@boolean)
    end

    it "should flatten out any nested union passed to it" do
      union = Type::Union.union(@boolean, @integer)
      union = Type::Union.union(union, @null)
      assert_equal 3, union.alternative_types.length
      assert union.alternative_types.include?(@boolean)
      assert union.alternative_types.include?(@integer)
      assert union.alternative_types.include?(@null)
    end

    it "should pick the least upper bound of numeric types rather than leave them in separate overlapping union clauses" do
      assert_equal @real, Type::Union.union(@real, @integer)
      assert_equal @complex, Type::Union.union(@rational, @complex)
    end

    it "should eliminate duplicates (and using type equality not just instance equality)" do
      assert_equal @complex, Type::Union.union(@complex, @complex)

      assert_equal Type::Union.union(@complex, @null), Type::Union.union(@complex, @complex, @null)
      assert_equal 2, Type::Union.union(@complex, @complex, @null).alternative_types.length

      # uses type equality
      assert_equal Type::Sequence.new(@boolean), Type::Union.union(Type::Sequence.new(@boolean), Type::Sequence.new(@boolean))
    end

    it "should compute least upper bounds of different sequence types via recursively taking the union of their parameter types" do
      seq_union = Type::Union.union(Type::Sequence.new(@boolean), Type::Sequence.new(@null))
      assert_equal Type::Sequence.new(Type::Union.union(@boolean, @null)), seq_union
    end

    it "should compute least upper bounds of different tuple types via recursively taking the union of their types slot-wise" do
      tup_union = Type::Union.union(Type::Tuple.new(@boolean, @integer), Type::Tuple.new(@null, @real))
      assert_equal Type::Tuple.new(Type::Union.union(@boolean, @null), @real), tup_union
    end

    describe "when computing least upper bounds of different object types" do
      it "should take only slots present in all the object types in the union" do
        union = Type::Union.union(
          Type::Object.new('Object', :foo => @integer, :bar => @boolean),
          Type::Object.new('Object', :boo => @integer, :bar => @boolean)
        )
        assert_equal Type::Object.new('Object', :bar => @boolean), union
      end

      it "should recursively taking the union of the types in their shared slots" do
        union = Type::Union.union(
          Type::Object.new('Object', :foo => @integer, :bar => @boolean),
          Type::Object.new('Object', :boo => @integer, :bar => @null)
        )
        assert_equal Type::Object.new('Object', :bar => Type::Union.union(@boolean, @null)), union
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
          Type::Object.new('TestClass2', :baz => @integer),

          Type::Object.new('TestClass', :foo => @boolean, :bar => @boolean),
          Type::Object.new('TestSubclass', :foo => @null, :baz => @boolean)
        )
        assert_equal 2, union.alternative_types.length
        assert_includes union.alternative_types, Type::Object.new('TestClass',
          :foo => Type::Union.union(@boolean, @null)
        )
        assert_includes union.alternative_types, Type::Object.new('TestClass2',
          :baz => @integer
        )
      end
    end


  end
end
