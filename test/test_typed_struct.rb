require 'test/common'
require 'typisch/typed'

describe "Typed" do

  before do
    @registry = Registry.new
  end

  it "should help you register a new object type for a class or module, registering it by default in the global registry and by a symbol corresponding to the class/module name" do
    Typisch.register do
      class Foo
        extend Typed
        register_type do
          property :title, :string
          property :bar, :Bar
        end
      end

      module Bar
        extend Typed
        register_type do
          property :title, :string
          property :foo, :Foo
        end
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
      extend Typed
      SPECIAL_REGISTRY = Typisch::Registry.new

      register_type(SPECIAL_REGISTRY, :type_of_baz) do
        property :title, :string
      end
    end

    baz_type = Baz::SPECIAL_REGISTRY[:type_of_baz]
    assert_instance_of Type::Object, baz_type
    assert_equal Baz, baz_type.class_or_module

  end
end
