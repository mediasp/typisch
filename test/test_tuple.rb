require 'test/common'

describe "Tuple types" do

  before do
    @registry = Registry.new
    [:boolean, :null, :complex, :real, :rational, :integer].each do |t|
      instance_variable_set("@#{t}", @registry[t])
    end
  end

  it "should subtype structurally width-wise, with a wider tuple a subtype of a compatible narrower one" do
    assert_operator Type::Tuple.new(@boolean), :<, Type::Tuple.new()
    assert_operator Type::Tuple.new(@boolean, @integer), :<, Type::Tuple.new(@boolean)
  end

  it "should not allow subtyping when the types of corresponding slots aren't compatible" do
    refute_operator Type::Tuple.new(@boolean), :<=, Type::Tuple.new(@null)
    refute_operator Type::Tuple.new(@boolean, @integer), :<=, Type::Tuple.new(@integer)
  end

  it "should subtype depth-wise, when the types of corresponding slots are themselves subtypes" do
    assert_operator Type::Tuple.new(@integer, @real), :<, Type::Tuple.new(@real, @complex)
    assert_operator Type::Tuple.new(@integer, @null), :<, Type::Tuple.new(@real, @null)
  end

  it "should subtype with a combination of width and depth subtyping" do
    assert_operator Type::Tuple.new(@integer, @null), :<, Type::Tuple.new(@real)
  end

  it "should let equality be reflexive" do
    assert_equal Type::Tuple.new(@boolean), Type::Tuple.new(@boolean)
  end

  it "should compute equality successfully for a recursive type (ie cyclic graph of types)" do
    # todo: less cludgey way of wiring up these cyclic object graphs
    recursive = Type::Tuple.allocate
    recursive.send(:initialize, recursive)

    assert_equal recursive, recursive
  end

  it "should equate bisimilar cyclic type graphs" do
    recursive = Type::Tuple.allocate
    recursive.send(:initialize, recursive)

    recursive2 = Type::Tuple.new(recursive)

    recursive3, recursive4 = Type::Tuple.allocate, Type::Tuple.allocate
    recursive3.send(:initialize, recursive4)
    recursive4.send(:initialize, recursive3)

    assert_equal recursive, recursive2
    assert_equal recursive2, recursive
    assert_equal recursive, recursive3
    assert_equal recursive2, recursive3
    assert_equal recursive3, recursive4
  end

  it "should subtype properly with cyclic type graphs / recursive types" do
    recursive = Type::Tuple.allocate
    recursive.send(:initialize, @integer, recursive)

    recursive1, recursive2 = Type::Tuple.allocate, Type::Tuple.allocate
    recursive1.send(:initialize, @real, recursive2)
    recursive2.send(:initialize, @integer, recursive1)

    recursive3 = Type::Tuple.new(@real, recursive, @boolean)
    assert_operator recursive3, :<, recursive1

    assert_operator Type::Tuple.new(@real), :>, recursive
    assert_operator Type::Tuple.new(@real), :>, recursive1
    assert_operator Type::Tuple.new(@real), :>, recursive2
    assert_operator Type::Tuple.new(@integer), :>, recursive2
    assert_nil Type::Tuple.new(@integer) <=> recursive1
    refute_operator Type::Tuple.new(@real), :<=, recursive2

    assert_operator recursive, :<, recursive1
    assert_operator recursive, :<, recursive2
    refute_operator recursive, :>, recursive1
  end

  it "should typecheck correctly" do
    tuple = Type::Tuple.new(@boolean, @integer)
    assert tuple === [true, 1]
    refute tuple === [1, true]
    refute tuple === [true, 1, nil]
    refute tuple === [true, 1].to_enum
  end

  it "should typecheck cyclic instances against cyclic types" do
    tuple = Type::Tuple.allocate
    tuple.send(:initialize, @integer, tuple)
    instance = [1]; instance << instance
    assert tuple === instance

    tuple2 = Type::Tuple.allocate
    tuple2.send(:initialize, @integer, Type::Tuple.new(@integer, tuple2))
    assert tuple2 === instance

    instance = [1, [1, [1]]]; instance[1][1] << instance
    assert tuple === instance

    instance = [1, [1, [true]]]; instance[1][1] << instance
    refute tuple === instance
    refute tuple2 === instance
  end
end
