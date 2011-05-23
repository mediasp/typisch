require 'test/common'

describe "Tuple types" do
  it "should subtype structurally width-wise, with a wider tuple a subtype of a compatible narrower one" do
    assert_operator Type::Tuple.new(Type::BOOLEAN), :<, Type::Tuple.new()
    assert_operator Type::Tuple.new(Type::BOOLEAN, Type::INTEGRAL), :<, Type::Tuple.new(Type::BOOLEAN)
  end
  
  it "should not allow subtyping when the types of corresponding slots aren't compatible" do
    refute_operator Type::Tuple.new(Type::BOOLEAN), :<=, Type::Tuple.new(Type::NULL)
    refute_operator Type::Tuple.new(Type::BOOLEAN, Type::INTEGRAL), :<=, Type::Tuple.new(Type::INTEGRAL)
  end

  it "should subtype depth-wise, when the types of corresponding slots are themselves subtypes" do
    assert_operator Type::Tuple.new(Type::INTEGRAL, Type::REAL), :<, Type::Tuple.new(Type::REAL, Type::COMPLEX)
    assert_operator Type::Tuple.new(Type::INTEGRAL, Type::NULL), :<, Type::Tuple.new(Type::REAL, Type::NULL)
  end
  
  it "should subtype with a combination of width and depth subtyping" do
    assert_operator Type::Tuple.new(Type::INTEGRAL, Type::NULL), :<, Type::Tuple.new(Type::REAL)
  end
  
  it "should let equality be reflexive" do
    assert_equal Type::Tuple.new(Type::BOOLEAN), Type::Tuple.new(Type::BOOLEAN)
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
    recursive.send(:initialize, Type::INTEGRAL, recursive)

    recursive1, recursive2 = Type::Tuple.allocate, Type::Tuple.allocate
    recursive1.send(:initialize, Type::REAL, recursive2)
    recursive2.send(:initialize, Type::INTEGRAL, recursive1)

    recursive3 = Type::Tuple.new(Type::REAL, recursive, Type::BOOLEAN)
    assert_operator recursive3, :<, recursive1

    assert_operator Type::Tuple.new(Type::REAL), :>, recursive
    assert_operator Type::Tuple.new(Type::REAL), :>, recursive1
    assert_operator Type::Tuple.new(Type::REAL), :>, recursive2
    assert_operator Type::Tuple.new(Type::INTEGRAL), :>, recursive2
    assert_nil Type::Tuple.new(Type::INTEGRAL) <=> recursive1
    refute_operator Type::Tuple.new(Type::REAL), :<=, recursive2
    
    assert_operator recursive, :<, recursive1
    assert_operator recursive, :<, recursive2
    refute_operator recursive, :>, recursive1
  end
end