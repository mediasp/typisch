require 'test/common'

describe "Type#canonicalize" do

  before do
    @registry = Registry.new
  end

  it "should return a type graph equal to the original one, but with all new instances, and with NamedPlaceholder wrappers eliminated" do
    type = @registry[:type] = Type::Object.new('TestClass', :foo =>
      Type::Sequence.new(
        Type::Tuple.new(
          @registry[:type]
        )
      )
    )

    canonicalized = type.canonicalize
    assert_equal type, canonicalized
    refute_same type, canonicalized

    assert_equal type[:foo], canonicalized[:foo]
    refute_same type[:foo], canonicalized[:foo]

    assert_equal type[:foo].type, canonicalized[:foo].type
    refute_same type[:foo].type, canonicalized[:foo].type

    assert_equal type[:foo].type[0], canonicalized[:foo].type[0]
    refute_same type[:foo].type[0], canonicalized[:foo].type[0]

    refute_same type[:foo].type[0], type
    assert Type::NamedPlaceholder === type[:foo].type[0]
    assert Type::Object === type

    assert_same canonicalized[:foo].type[0], canonicalized
    assert Type::Object === canonicalized
  end

  it "should catch and complain about ill-formed uses of recursion, where a cyclic reference has no constructor types in the cycle" do
    # Cases with only unions in the cycle, eg "foo = foo union foo" - makes no sense

    assert_raises(IllFormedRecursiveType) do
      u = Type::Union.allocate
      u.send(:initialize, u)
      u.canonicalize
    end

    assert_raises(IllFormedRecursiveType) do
      u = Type::Union.allocate
      u.send(:initialize, u, u)
      u.canonicalize
    end
    assert_raises(IllFormedRecursiveType) do
      u = Type::Union.allocate
      u.send(:initialize, Type::Union.new(u))
      u.canonicalize
    end

    assert_raises(IllFormedRecursiveType) do
      u = Type::Union.allocate
      u.send(:initialize, Type::Union.new(Type::Union.new(u)))
      u.canonicalize
    end

    # Unions and NamedPlaceholder:

    @registry = Registry.new
    assert_raises(IllFormedRecursiveType) do
      u = @registry[:u] = Type::Union.new(@registry[:u])
      u.canonicalize
    end

    @registry = Registry.new
    assert_raises(IllFormedRecursiveType) do
      u = @registry[:u]
      @registry[:u] = Type::Union.new(u)
      u.canonicalize
    end

    @registry = Registry.new
    assert_raises(IllFormedRecursiveType) do
      u = @registry[:u] = Type::Union.new(Type::Union.new(@registry[:u]))
      u.canonicalize
    end

    @registry = Registry.new
    assert_raises(IllFormedRecursiveType) do
      u = @registry[:u] = Type::Union.new(@registry[:v])
      v = @registry[:v] = Type::Union.new(@registry[:u])
      u.canonicalize
    end

    @registry = Registry.new
    assert_raises(IllFormedRecursiveType) do
      u = @registry[:u] = @registry[:v]
      @registry[:v] = Type::Union.new(u)
      u.canonicalize
    end

    @registry = Registry.new
    assert_raises(IllFormedRecursiveType) do
      u = Type::Union.new(@registry[:v])
      @registry[:v] = @registry[:u]
      @registry[:u] = u
      u.canonicalize
    end


    # Just NamedPlaceholder:
    # eg "foo = foo" - makes even less sense
    @registry = Registry.new
    assert_raises(IllFormedRecursiveType) do
      cycle = @registry[:cycle] = @registry[:cycle]
      cycle.canonicalize
    end

    @registry = Registry.new
    assert_raises(IllFormedRecursiveType) do
      foo = @registry[:foo] = @registry[:bar]
      @registry[:bar] = @registry[:foo]
      foo.canonicalize
    end

    # this should work fine though, even though canonicalise
    # is called twice on the same NamedPlaceholder, the two occurrences aren't in the
    # same cycle. may break if the logic for NamedPlaceholder#canonicalise gets buggered
    @registry = Registry.new
    foo = @registry[:foo]
    tuple = Type::Tuple.new(foo, foo)
    @registry[:foo] = @registry[:boolean]
    tuple.canonicalize
  end

  it "should work fine with legitimate cyclic type graphs which have a constructor type in the cycle" do
    t = Type::Sequence.allocate
    t.send(:initialize, t)
    assert_equal t, t.canonicalize
    refute_same t, t.canonicalize

    @registry = Registry.new
    list = @registry[:list] = Type::Union.new(Type::Tuple.new(@registry[:integer], @registry[:list]), @registry[:null])
    list.canonicalize
    list.alternative_types[0][1].canonicalize
    # not strictly relevant, but while we're on (co)recursive types, just to demo this classic of the genre at work:
    assert list === [1, [2, [3, nil]]]
    a = [1]; a << a; assert list === a

    list = Type::Union.allocate
    list.send(:initialize, Type::Tuple.new(@registry[:integer], list), @registry[:null])
    list.canonicalize

    foo = Type::Union.allocate
    foo.send(:initialize, Type::Sequence.new(foo))
    foo.canonicalize
    foo.alternative_types[0].canonicalize

    foo = Type::Union.allocate
    foo.send(:initialize, Type::Object.new('Object', :foo => foo))
    foo.canonicalize
    foo.alternative_types[0].canonicalize

    @registry = Registry.new
    foo = @registry[:foo] = Type::Sequence.new(@registry[:bar])
    bar = @registry[:bar] = Type::Tuple.new(@registry[:foo])
    foo.canonicalize
    bar.canonicalize
  end

  it "should canonicalize an empty union to Nothing" do
    assert_same @registry[:nothing], Type::Union.new().canonicalize
  end

  it "should flatten out nested unions" do
    union = Type::Union.new(Type::Union.new(@registry[:boolean]))
    refute Type::Boolean === union.alternative_types[0]
    assert Type::Boolean === union.canonicalize.alternative_types[0]

    union = Type::Union.new(@registry[:boolean], Type::Union.new(@registry[:integer]))
    assert Type::Boolean === union.canonicalize.alternative_types[0]
    assert Type::Numeric === union.canonicalize.alternative_types[1]
  end

  it "should replace a single-term union with that one term" do
    union = Type::Union.new(@registry[:integer], @registry[:complex])
    assert_same @registry[:complex], union.canonicalize
  end

  it "should reduce the terms of a union to a minimal covering set wrt subtyping, in particular taking the upper bound when taking union of a chain etc" do
    # see test_poset_algos for more coverage of the algo it uses under the hood here

    union = Type::Union.new(@registry[:integer], @registry[:complex], @registry[:boolean])
    assert_same @registry[:complex], union.canonicalize.alternative_types[0]
    assert_same @registry[:boolean], union.canonicalize.alternative_types[1]

    union = Type::Union.new(Type::Object.new('TestClass'), Type::Object.new('TestSubclass'))
    assert Type::Object === union.canonicalize
    assert_equal TestClass, union.canonicalize.class_or_module

    union = Type::Union.new(Type::Object.new('TestClass'), Type::Object.new('TestSubclass'), Type::Object.new('TestModule'))
    assert_equal TestClass, union.canonicalize.alternative_types[0].class_or_module
    assert_equal TestModule, union.canonicalize.alternative_types[1].class_or_module

    union = Type::Union.new(
      Type::Object.new('Object', :a => @registry[:boolean]),
      Type::Object.new('Object', :a => @registry[:boolean], :c => @registry[:boolean]),
      Type::Object.new('Object', :a => @registry[:boolean], :d => @registry[:boolean]),
      Type::Object.new('Object', :a => @registry[:boolean], :b => @registry[:boolean]),
      Type::Object.new('Object', :b => @registry[:boolean])
    )
    assert_equal 2, union.canonicalize.alternative_types.length
    assert_equal [[:a],[:b]], union.canonicalize.alternative_types.map {|t| t.property_names}.sort_by(&:to_s)
  end

  it "should replace a two-term union with one of the clauses when it's a supertype of the other" do
    union = Type::Union.new(@registry[:complex], @registry[:integer])
    assert_same @registry[:complex], union.canonicalize
  end

end
