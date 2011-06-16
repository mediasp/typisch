require 'test/common'

describe "Registry" do

  before do
    @registry = Registry.new
  end

  it "should ship with special global singleton types already registered" do
    assert_instance_of Type::Boolean,   @registry[:boolean]
    assert_instance_of Type::Null,      @registry[:null]
    assert_instance_of Type::String,    @registry[:string]
    assert_instance_of Type::Numeric,   @registry[:complex]
    assert_instance_of Type::Numeric,   @registry[:real]
    assert_instance_of Type::Numeric,   @registry[:rational]
    assert_instance_of Type::Numeric,   @registry[:integer]
    assert_instance_of Type::Any,       @registry[:any]
    assert_instance_of Type::Nothing,   @registry[:nothing]
  end

  it "should let you register your own types" do
    my_type = Type::Tuple.new(@registry[:integer], @registry[:boolean])

    @registry[:my_type] = my_type

    assert_same my_type, @registry[:my_type]
  end

  it "should not let you overwrite an already-registered type" do
    my_type = Type::Tuple.new(@registry[:integer], @registry[:boolean])

    assert_raises(Error) do
      @registry[:boolean] = my_type
    end
  end

  it "should let you get a 'forward reference' to a type which has not yet been registered, returning a convincing proxy wrapper which once the type is available will proxy through to it" do
    # something like smalltalk's "become" would make this a lot nicer:
    # http://gbracha.blogspot.com/2009/07/miracle-of-become.html

    my_type = Type::Tuple.new(@registry[:integer], @registry[:boolean])

    reference = @registry[:coming_soon]
    assert Type::NamedPlaceholder === reference
    assert_equal ":coming_soon", reference.to_s

    @registry[:coming_soon] = my_type

    # the proxy wrapper is very convincing as a substitute for the real thing:

    # =='s it
    assert_equal my_type, reference

    # looks like it's of the same class as the proxied type (important for some of the
    # subtyping etc algorithms to treat these proxies as they would the real thing)
    assert_equal my_type.class, reference.class
    assert reference.is_a?(Type::Tuple)
    assert reference.instance_of?(Type::Tuple)

    # proxies through methods specific to Type::Tuple (or whatever particular Type subclass it is)
    assert_equal reference.types, my_type.types
  end

  it "should return at most one forward reference for any type name" do
    # this is an optimisation, but saves the subtyping and other type-level algorithms
    # a bunch of work by reducing the number of distinct instance identities in the
    # (possibly cyclic) graph which they operate on.
    assert_same @registry[:coming_soon], @registry[:coming_soon]
  end

  it "should complain if you try to find out anything about a forward reference where the type it references hasn't yet been registered" do
    assert_raises(NameResolutionError) do
      @registry[:coming_soon] == @registry[:boolean]
    end
  end

  it "should let you dup a registry safely" do
    dup = @registry.dup
    dup[:foo] = @registry[:boolean]
    refute_same dup.types_by_name, @registry.types_by_name
    assert Typisch::Type::Boolean === dup[:foo]
    refute Typisch::Type::Boolean === @registry[:foo]
  end

  it "should let you merge registries" do
    @registry2 = Registry.new
    @registry2[:foo] = @registry[:boolean]
    @registry[:bar] = @registry[:integer]
    merged = @registry.merge(@registry2)
    assert Typisch::Type::Boolean === merged[:foo]
    assert Typisch::Type::Numeric === merged[:bar]
    refute Typisch::Type::Boolean === @registry[:foo]
  end

  it "should ensure all types registered in a register block get canonicalized in a batch afterwards (and any recursion or name resolution errors caught)" do
    assert_raises(IllFormedRecursiveType) do
      @registry.register do
        register :foo, :foo
      end
    end

    @registry = Registry.new
    assert_raises(NameResolutionError) do
      @registry.register do
        register :foo, :bar
      end
    end

    @registry = Registry.new
    @registry.register do
      register :test, sequence(:test)
    end
    # check there is just the one node in the canonicalized graph, the NamedPlaceholder wrapper node
    # used to issue a forward reference to 'test' prior to its registration, has been eliminated.
    assert Type::Sequence === @registry[:test]
    assert Type::Sequence === @registry[:test].type


    @registry = Registry.new
    @registry.register do
      register :foo, sequence(:bar)
      register :bar, tuple(:foo)
    end
    # check that it canonicalized all registered types together, rather than doing them separately.
    # the difference would be that you'd see distinct instances for the same types between @registry[:foo]
    # and @registry[:bar]
    assert_same @registry[:bar], @registry[:foo].type
    assert_same @registry[:foo], @registry[:bar][0]
  end

end
