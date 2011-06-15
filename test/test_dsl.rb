require 'test/common'

describe "Registry#register / DSLContext" do

  before do
    @registry = Registry.new
  end

  # todo: some more fine-grained specs for how this works
  it "should let you create and register types using some nice syntax" do
    @registry.register do
      register :alias_for_boolean, :boolean

      register :book, :object do
        property :title, :string
        property :subtitle, union(:string, :null)
        property :author, :author
      end

      register :author, :object do
        property :name, :string
        property :age,  :integer
        property :books, sequence(:book)
      end
    end

    assert_instance_of Type::Boolean, @registry[:alias_for_boolean]

    book, author = @registry[:book], @registry[:author]
    assert_instance_of Type::Object, book
    assert_instance_of Type::String, book[:title]
    assert_instance_of Type::Union,  book[:subtitle]
    assert_instance_of Type::String, book[:subtitle].alternative_types[0]
    assert_instance_of Type::Null,   book[:subtitle].alternative_types[1]

    # todo: make these assert_same once we have type graph canonicalization in place
    assert_equal book[:author], author
    assert_equal author, book[:author]


    assert_instance_of Type::String, author[:name]
    assert_instance_of Type::Numeric, author[:age]
    assert_instance_of Type::Sequence, author[:books]

    # todo: make these assert_same once we have type graph canonicalization in place
    assert_equal book, author[:books].type
    assert_equal author[:books].type, book
  end

  describe "Class or Module-based DSL via Module#register_type" do

    it "should help you register a new object type for a class or module, registering it by default in the global registry and by a symbol corresponding to the class/module name" do
      class Foo
        register_type do
          property :title, :string
          property :bar, :Bar
        end
      end

      module Bar
        register_type do
          property :title, :string
          property :foo, :Foo
        end
      end

      # look them up in the global registry:
      foo_type, bar_type = Typisch[:Foo], Typisch[:Bar]

      assert_instance_of Type::Object, foo_type
      assert_equal Foo, foo_type.class_or_module

      # check the forward reference from one class to the next got hooked up OK
      assert_equal bar_type, foo_type[:bar]
      assert_equal foo_type, bar_type[:foo]
    end

    it "should let you specify what to register it as and a particular registry in which to do so" do
      class Baz
        SPECIAL_REGISTRY = Typisch::Registry.new

        register_type(:type_of_baz, SPECIAL_REGISTRY) do
          property :title, :string
        end
      end

      baz_type = Baz::SPECIAL_REGISTRY[:type_of_baz]
      assert_instance_of Type::Object, baz_type
      assert_equal Baz, baz_type.class_or_module

    end

  end
end
