require 'test/common'

describe "Object types" do
  it "should subtype structurally width-wise, with extra properties allowed on a subtype" do
    assert_operator Type::Object.new('Object', :foo => Type::BOOLEAN), :<, Type::Object.new('Object')
    assert_operator Type::Object.new('Object', :foo => Type::BOOLEAN, :bar => Type::INTEGRAL), :<, Type::Object.new('Object', :foo => Type::BOOLEAN)
    assert_operator Type::Object.new('Object', :foo => Type::BOOLEAN, :bar => Type::INTEGRAL), :<, Type::Object.new('Object', :bar => Type::INTEGRAL)
  end
  
  it "should not allow subtyping when the types of corresponding slots aren't compatible" do
    refute_operator Type::Object.new('Object', :foo => Type::BOOLEAN), :<=, Type::Object.new('Object', :foo => Type::NULL)
    refute_operator Type::Object.new('Object', :foo => Type::BOOLEAN, :bar => Type::INTEGRAL), :<=, Type::Object.new('Object', :foo => Type::INTEGRAL)
  end

  it "should subtype depth-wise, when the types of corresponding slots are themselves subtypes" do
    assert_operator Type::Object.new('Object', :foo => Type::INTEGRAL, :bar => Type::REAL), :<, Type::Object.new('Object', :foo => Type::REAL, :bar => Type::COMPLEX)
    assert_operator Type::Object.new('Object', :foo => Type::INTEGRAL, :bar => Type::NULL), :<, Type::Object.new('Object', :foo => Type::REAL, :bar => Type::NULL)
  end
  
  it "should subtype with a combination of width and depth subtyping" do
    assert_operator Type::Object.new('Object', :foo => Type::INTEGRAL, :bar => Type::NULL), :<, Type::Object.new('Object', :foo => Type::REAL)
  end
  
  it "should let equality be reflexive" do
    assert_equal Type::Object.new('Object', :foo => Type::BOOLEAN), Type::Object.new('Object', :foo => Type::BOOLEAN)
  end
  
  it "should compute equality successfully for a recursive type (ie cyclic graph of types)" do
    # todo: less cludgey way of wiring up these cyclic object graphs
    recursive = Type::Object.allocate
    recursive.send(:initialize, 'Object', :foo => recursive)

    assert_equal recursive, recursive
  end

  it "should equate bisimilar cyclic type graphs" do
    recursive = Type::Object.allocate
    recursive.send(:initialize, 'Object', :foo => recursive)

    recursive2 = Type::Object.new('Object', :foo => recursive)

    recursive3, recursive4 = Type::Object.allocate, Type::Object.allocate
    recursive3.send(:initialize, 'Object', :foo => recursive4)
    recursive4.send(:initialize, 'Object', :foo => recursive3)

    assert_equal recursive, recursive2
    assert_equal recursive2, recursive
    assert_equal recursive, recursive3
    assert_equal recursive2, recursive3
    assert_equal recursive3, recursive4
  end
  
  it "should subtype properly with cyclic type graphs / recursive types" do
    recursive = Type::Object.allocate
    recursive.send(:initialize, 'Object', :number => Type::INTEGRAL, :another => recursive)

    recursive1, recursive2 = Type::Object.allocate, Type::Object.allocate
    recursive1.send(:initialize, 'Object', :number => Type::REAL, :another => recursive2)
    recursive2.send(:initialize, 'Object', :number => Type::INTEGRAL, :another => recursive1)

    recursive3 = Type::Object.new('Object', :number => Type::REAL, :another => recursive, :extra => Type::BOOLEAN)
    assert_operator recursive3, :<, recursive1

    assert_operator Type::Object.new('Object', :number => Type::REAL), :>, recursive
    assert_operator Type::Object.new('Object', :number => Type::REAL), :>, recursive1
    assert_operator Type::Object.new('Object', :number => Type::REAL), :>, recursive2
    assert_operator Type::Object.new('Object', :number => Type::INTEGRAL), :>, recursive2
    assert_nil Type::Object.new('Object', :number => Type::INTEGRAL) <=> recursive1
    refute_operator Type::Object.new('Object', :number => Type::REAL), :<=, recursive2
    
    assert_operator recursive, :<, recursive1
    assert_operator recursive, :<, recursive2
    refute_operator recursive, :>, recursive1
  end
  
  class TestClass; end
  module TestModule; end
  class TestSubclass < TestClass; include TestModule; end
  class TestClass2; include TestModule; end
  
  it "should subtype according to the inheritance graph based on ruby classes or modules with equivalent names to the specified type tags" do
    assert_operator Type::Object.new('TestSubclass'), :<, Type::Object.new('TestClass')
    refute_operator Type::Object.new('TestSubclass'), :>=, Type::Object.new('TestClass')

    assert_operator Type::Object.new('TestClass'), :<, Type::Object.new('Object')
    assert_operator Type::Object.new('TestSubclass'), :<, Type::Object.new('Object')

    assert_nil Type::Object.new('TestClass') <=> Type::Object.new('TestModule')
    refute_operator Type::Object.new('TestClass'), :<, Type::Object.new('TestModule')

    assert_nil Type::Object.new('TestClass') <=> Type::Object.new('TestModule')
    refute_operator Type::Object.new('TestClass'), :<, Type::Object.new('TestModule')
    assert_operator Type::Object.new('TestSubclass'), :<, Type::Object.new('TestModule')
    assert_operator Type::Object.new('TestClass2'), :<, Type::Object.new('TestModule')
  end

  it "should subtype via a combo of the tag name inheritance graph, and structural subtyping; where both kinds of subtyping are required to hold, not just one or the other" do
    assert_operator Type::Object.new('TestClass', :foo => Type::BOOLEAN), :<, Type::Object.new('Object')
    assert_operator Type::Object.new('TestClass', :foo => Type::BOOLEAN), :<, Type::Object.new('Object', :foo => Type::BOOLEAN)
    assert_operator Type::Object.new('TestSubclass', :foo => Type::INTEGRAL, :bar => Type::BOOLEAN), :<, Type::Object.new('TestClass', :foo => Type::REAL)

    refute_operator Type::Object.new('TestClass', :foo => Type::INTEGRAL), :<=, Type::Object.new('TestClass2', :foo => Type::INTEGRAL)

    refute_operator Type::Object.new('TestSubclass', :foo => Type::REAL), :<=, Type::Object.new('TestClass', :foo => Type::INTEGRAL)
  end
end