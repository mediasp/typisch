require 'test/common'

describe "basic Type::Tagged subclasses (Boolean, Null, Numeric, ...)" do

  before do
    @registry = Registry.new
    [:boolean, :null, :complex, :real, :rational, :integer].each do |t|
      instance_variable_set("@#{t}", @registry[t])
    end
  end

  it "should be non-overlapping between the different subclasses" do
    refute_equal @boolean, @null
    refute_equal @boolean, @real
    refute_equal @null, @real

    refute_operator @boolean, :<, @null
    refute_operator @boolean, :<=, @null
    refute_operator @boolean, :>, @null
    refute_operator @boolean, :>=, @null

    refute_operator @boolean, :<, @real
    refute_operator @boolean, :<=, @real
    refute_operator @boolean, :>, @real
    refute_operator @boolean, :>=, @real

    refute_operator @real, :<, @null
    refute_operator @real, :<=, @null
    refute_operator @real, :>, @null
    refute_operator @real, :>=, @null

    assert_nil @boolean <=> @null
    assert_nil @real <=> @null
    assert_nil @boolean <=> @real
  end

  it "should have types equalling themselves" do
    assert_equal @boolean, @boolean
    assert_equal @null, @null
    assert_equal @complex, @complex
    assert_equal @real, @real
    assert_equal @rational, @rational
    assert_equal @integer, @integer
  end

  describe "Numeric tower" do
    it "should be arranged in a linear subtyping order: Integer < Rational < Real < Complex" do
      assert_operator @integer, :<, @rational
      assert_operator @integer, :<, @real
      assert_operator @integer, :<, @complex
      assert_operator @rational, :<, @real
      assert_operator @rational, :<, @complex
      assert_operator @real, :<, @complex
      refute_operator @integer, :>=, @rational
      refute_operator @integer, :>=, @real
      refute_operator @integer, :>=, @complex
      refute_operator @rational, :>=, @real
      refute_operator @rational, :>=, @complex
      refute_operator @real, :>=, @complex

      assert_equal -1, @integer <=> @real
      assert_equal 1, @real <=> @integer
      assert_equal 0, @real <=> @real
    end
  end
end
