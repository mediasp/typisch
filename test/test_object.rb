require 'test/common'

describe "Object types" do
  before do
    @registry = Registry.new
    [:boolean, :null, :complex, :real, :rational, :integer, :string].each do |t|
      instance_variable_set("@#{t}", @registry[t])
    end
  end

  it "should subtype structurally width-wise, with extra properties allowed on a subtype" do
    assert_operator Type::Object.new('Object', :foo => @boolean), :<, Type::Object.new('Object')
    assert_operator Type::Object.new('Object', :foo => @boolean, :bar => @integer), :<, Type::Object.new('Object', :foo => @boolean)
    assert_operator Type::Object.new('Object', :foo => @boolean, :bar => @integer), :<, Type::Object.new('Object', :bar => @integer)
  end

  it "should not allow subtyping when the types of corresponding slots aren't compatible" do
    refute_operator Type::Object.new('Object', :foo => @boolean), :<=, Type::Object.new('Object', :foo => @null)
    refute_operator Type::Object.new('Object', :foo => @boolean, :bar => @integer), :<=, Type::Object.new('Object', :foo => @integer)
  end

  it "should subtype depth-wise, when the types of corresponding slots are themselves subtypes" do
    assert_operator Type::Object.new('Object', :foo => @integer, :bar => @real), :<, Type::Object.new('Object', :foo => @real, :bar => @complex)
    assert_operator Type::Object.new('Object', :foo => @integer, :bar => @null), :<, Type::Object.new('Object', :foo => @real, :bar => @null)
  end

  it "should subtype with a combination of width and depth subtyping" do
    assert_operator Type::Object.new('Object', :foo => @integer, :bar => @null), :<, Type::Object.new('Object', :foo => @real)
  end

  it "should let equality be reflexive" do
    assert_equal Type::Object.new('Object', :foo => @boolean), Type::Object.new('Object', :foo => @boolean)
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
    recursive.send(:initialize, 'Object', :number => @integer, :another => recursive)

    recursive1, recursive2 = Type::Object.allocate, Type::Object.allocate
    recursive1.send(:initialize, 'Object', :number => @real, :another => recursive2)
    recursive2.send(:initialize, 'Object', :number => @integer, :another => recursive1)

    recursive3 = Type::Object.new('Object', :number => @real, :another => recursive, :extra => @boolean)
    assert_operator recursive3, :<, recursive1

    assert_operator Type::Object.new('Object', :number => @real), :>, recursive
    assert_operator Type::Object.new('Object', :number => @real), :>, recursive1
    assert_operator Type::Object.new('Object', :number => @real), :>, recursive2
    assert_operator Type::Object.new('Object', :number => @integer), :>, recursive2
    assert_nil Type::Object.new('Object', :number => @integer) <=> recursive1
    refute_operator Type::Object.new('Object', :number => @real), :<=, recursive2

    assert_operator recursive, :<, recursive1
    assert_operator recursive, :<, recursive2
    refute_operator recursive, :>, recursive1
  end

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
    assert_operator Type::Object.new('TestClass', :foo => @boolean), :<, Type::Object.new('Object')
    assert_operator Type::Object.new('TestClass', :foo => @boolean), :<, Type::Object.new('Object', :foo => @boolean)
    assert_operator Type::Object.new('TestSubclass', :foo => @integer, :bar => @boolean), :<, Type::Object.new('TestClass', :foo => @real)

    refute_operator Type::Object.new('TestClass', :foo => @integer), :<=, Type::Object.new('TestClass2', :foo => @integer)

    refute_operator Type::Object.new('TestSubclass', :foo => @real), :<=, Type::Object.new('TestClass', :foo => @integer)
  end

  it "should typecheck the object by class/module" do
    assert Type::Object.new('TestClass') === TestClass.new
    assert Type::Object.new('TestClass') === TestSubclass.new
    refute Type::Object.new('TestClass') === Object.new

    assert Type::Object.new('TestModule') === TestClass2.new
    assert Type::Object.new('TestModule') === TestSubclass.new
    refute Type::Object.new('TestModule') === TestClass.new

    assert Type::Object.new('TestSubclass') === TestSubclass.new
    refute Type::Object.new('TestSubclass') === TestClass.new
  end

  FooBar = Struct.new(:foo, :bar)

  it "should typecheck the object's properties" do
    assert Type::Object.new('Object', :foo => @boolean) === FooBar.new(true, nil)
    refute Type::Object.new('Object', :foo => @boolean) === FooBar.new(123, nil)

    assert Type::Object.new('Object', :foo => @boolean, :bar => @integer) === FooBar.new(true, 123)
    refute Type::Object.new('Object', :foo => @boolean, :bar => @integer) === FooBar.new(true, 'x')
    refute Type::Object.new('Object', :foo => @boolean, :bar => @integer) === FooBar.new('x', 123)

    refute Type::Object.new('Object', :foo => @boolean, :bar => @integer) === Object.new
  end

  it "should require both class and properties to typecheck" do
    assert Type::Object.new('FooBar', :foo => @boolean, :bar => @integer) === FooBar.new(true, 123)
    refute Type::Object.new('FooBar', :foo => @boolean, :bar => @integer) === Struct.new(:foo, :bar).new(true, 123)
    refute Type::Object.new('TestClass', :foo => @boolean, :bar => @integer) === FooBar.new(true, 123)
    refute Type::Object.new('FooBar', :foo => @boolean, :bar => @integer) === FooBar.new(true, nil)
  end

  Book = Struct.new(:title, :author)
  Author = Struct.new(:title, :books)

  it "should type-check cyclic object graphs against cyclic schemas" do
    book = Type::Object.allocate
    author = Type::Object.allocate
    book.send(:initialize, 'Book', :title => @string, :author => author)
    author.send(:initialize, 'Author', :title => @string, :books => Type::Sequence.new(book))

    book_instance = Book.new('A Concise History of Posters', nil)
    author_instance = Author.new('John Barnicoat', [book_instance])
    book_instance.author = author_instance

    assert book === book_instance
    assert author === author_instance
  end
end
