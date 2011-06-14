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
    it "should allow either syntax: <type>.union(other) or Type::Union.new(type, other)" do
      assert_equal \
        Type::Union.new(@boolean, @integer),
        @boolean.union(@integer)
    end

    it "should not be sensitive to ordering when doing comparisons" do
      assert_equal \
        Type::Union.new(@boolean, @integer),
        Type::Union.new(@integer, @boolean)
    end

    it "should have an empty union equal to NOTHING" do
      assert_equal @nothing, Type::Union.new()
    end

    it "should have a single-clause Union equal to the single item on its own" do
      assert_equal @boolean, Type::Union.new(@boolean)
    end

    it "should have a nested union equal to the flattened-out version" do
      union = Type::Union.new(@boolean, @integer)
      union = Type::Union.new(union, @null)
      assert_equal union, Type::Union.new(@boolean, @integer, @null)
    end

    it "should have the things in the union be subtypes of it (and things not, not)" do
      union = Type::Union.new(@boolean, @integer)
      assert @boolean < union
      assert @integer < union
      assert_false @null < union
    end

    it "should equate the upper bound with the union in cases where it contains an upper bound" do
      assert_equal @real, Type::Union.new(@real, @integer)
      assert_equal @complex, Type::Union.new(@rational, @complex)
    end

    it "should have the union of sequences be a subtype of a sequence of unions" do
      union_seq = Type::Union.new(Type::Sequence.new(@boolean), Type::Sequence.new(@null))
      seq_union = Type::Sequence.new(Type::Union.new(@boolean, @null))
      assert_operator union_seq, :<, seq_union
    end

    it "should not mind a duplicate" do
      assert_equal @complex, Type::Union.new(@complex, @complex)

      assert_equal Type::Union.new(@complex, @null), Type::Union.new(@complex, @complex, @null)

      # uses type equality
      assert_equal Type::Sequence.new(@boolean), Type::Union.new(Type::Sequence.new(@boolean), Type::Sequence.new(@boolean))
    end

    it "should have a union of tuples be a subtype of a tuple of unions" do
      union_tup = Type::Union.new(Type::Tuple.new(@boolean, @integer), Type::Tuple.new(@null, @real))
      tup_union = Type::Tuple.new(Type::Union.new(@boolean, @null), @real)
      assert_operator union_tup, :<, tup_union
    end

    describe "unions of object types" do
      it "should allow subtypes where they subtype any clause of the union, even when type tags don't differ (this requires backtracking)" do
        union = Type::Union.new(
          (first_clause = Type::Object.new('Object', :foo => @integer)),
          Type::Object.new('Object', :bar => @integer)
        )

        # this will test twice against the two clauses in order. the first will fail, and it'll backtrack;
        # the second will then succeed:
        assert_operator Type::Object.new('Object', :bar => @integer, :baz => @boolean), :<=, union

        # check that the first test didn't polute the state of the subtyper, ie that it
        # backtracked cleanly. important that we use the same actual instance for that first clause:
        refute_operator Type::Object.new('Object', :bar => @integer, :baz => @boolean), :<=, first_clause
        # although actually, since the subtyper doesn't at present maintain state between runs, we
        # need something a bit more tricksy to test this, see next test

        # check something works against the first clause too
        assert_operator Type::Object.new('Object', :foo => @integer, :baz => @boolean), :<=, union

        # and something which satisfies both clauses
        assert_operator Type::Object.new('Object', :foo => @integer, :bar => @integer, :baz => @boolean), :<=, union

        # something which satisfies neither:
        refute_operator Type::Object.new('Object', :baz => @boolean), :<=, union
      end

      # this example would trip up the subtyper if it didn't backtrack safely after eliminating the first clause
      # in the union
      it "should backtrack safely when checking subtyping against multiple clauses of a union" do
        union = Type::Union.new(
          @integer,
          Type::Object.new('Object', :property => @integer)
        )
        type = Type::Object.allocate
        type.send(:initialize, 'Object', :property => type)
        def type.to_s; 'the_recursive_type'; end # avoid .inspect stack trace problems printing any error

        refute_operator type, :<=, union
      end

      it "should allow a union to be a subtype of something only when all of its clauses are a subtype of it" do
        union = Type::Union.new(
          Type::Object.new('Object', :foo => @integer),
          Type::Object.new('Object', :bar => @integer)
        )
        assert_operator union, :<=, Type::Object.new('Object')

        refute_operator union, :<=, Type::Object.new('Object', :foo => @integer)
        refute_operator union, :<=, Type::Object.new('Object', :bar => @integer)
        refute_operator union, :<=, Type::Object.new('Object', :xyz => @integer)
      end

      # we might relax this requirement, depending:
      it "should not simplify unions to be equal to a crude upper bound" do
        union = Type::Union.new(
          Type::Object.new('Object', :foo => @integer),
          Type::Object.new('Object', :bar => @integer)
        )
        # the union is a strict subtype of this, not equal:
        assert_operator Type::Object.new('Object'), :>, union
      end

      it "should, when type tags have a common upper bound amongst them, have the union equal the upper bound" do
        union = Type::Union.new(
          Type::Object.new('TestSubclass'),
          Type::Object.new('TestClass')
        )
        assert_equal Type::Object.new('TestClass'), union

        union = Type::Union.new(
          Type::Object.new('TestClass'),
          Type::Object.new('TestSubclass')
        )
        assert_equal Type::Object.new('TestClass'), union

        union = Type::Union.new(
          Type::Object.new('TestClass2'),
          Type::Object.new('TestSubclass'),
          Type::Object.new('TestModule')
        )
        assert_equal Type::Object.new('TestModule'), union
      end

      it "should, when there are non-overlapping groups some of which can be unified, have the union equal to the union of the unified upper bounds" do
        union = Type::Union.new(
          # one group
          Type::Object.new('TestClass2'),
          # another
          Type::Object.new('TestClass'),
          Type::Object.new('TestSubclass')
        )
        assert_equal Type::Union.new(
          Type::Object.new('TestClass2'),
          Type::Object.new('TestClass')
        ), union
      end

      it "should unify properties within these groups but leave differences in properties intact across these groups" do
      end
    end


  end
end
