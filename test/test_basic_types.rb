require 'test/common'

describe "basic Type::Tagged subclasses (Boolean, Null, Numeric, ...)" do

  it "should be non-overlapping between the different subclasses" do    
    refute_equal Type::BOOLEAN, Type::NULL
    refute_equal Type::BOOLEAN, Type::REAL
    refute_equal Type::NULL, Type::REAL

    refute_operator Type::BOOLEAN, :<, Type::NULL
    refute_operator Type::BOOLEAN, :<=, Type::NULL
    refute_operator Type::BOOLEAN, :>, Type::NULL
    refute_operator Type::BOOLEAN, :>=, Type::NULL

    refute_operator Type::BOOLEAN, :<, Type::REAL
    refute_operator Type::BOOLEAN, :<=, Type::REAL
    refute_operator Type::BOOLEAN, :>, Type::REAL
    refute_operator Type::BOOLEAN, :>=, Type::REAL

    refute_operator Type::REAL, :<, Type::NULL
    refute_operator Type::REAL, :<=, Type::NULL
    refute_operator Type::REAL, :>, Type::NULL
    refute_operator Type::REAL, :>=, Type::NULL

    assert_nil Type::BOOLEAN <=> Type::NULL
    assert_nil Type::REAL <=> Type::NULL
    assert_nil Type::BOOLEAN <=> Type::REAL
  end

  it "should have types equalling themselves" do
    assert_equal Type::BOOLEAN, Type::BOOLEAN
    assert_equal Type::NULL, Type::NULL
    assert_equal Type::COMPLEX, Type::COMPLEX
    assert_equal Type::REAL, Type::REAL
    assert_equal Type::RATIONAL, Type::RATIONAL
    assert_equal Type::INTEGRAL, Type::INTEGRAL
  end

  describe "Numeric tower" do
    it "should be arranged in a linear subtyping order: Integral < Rational < Real < Complex" do
      assert_operator Type::INTEGRAL, :<, Type::RATIONAL
      assert_operator Type::INTEGRAL, :<, Type::REAL
      assert_operator Type::INTEGRAL, :<, Type::COMPLEX
      assert_operator Type::RATIONAL, :<, Type::REAL
      assert_operator Type::RATIONAL, :<, Type::COMPLEX
      assert_operator Type::REAL, :<, Type::COMPLEX
      refute_operator Type::INTEGRAL, :>=, Type::RATIONAL
      refute_operator Type::INTEGRAL, :>=, Type::REAL
      refute_operator Type::INTEGRAL, :>=, Type::COMPLEX
      refute_operator Type::RATIONAL, :>=, Type::REAL
      refute_operator Type::RATIONAL, :>=, Type::COMPLEX
      refute_operator Type::REAL, :>=, Type::COMPLEX

      assert_equal -1, Type::INTEGRAL <=> Type::REAL
      assert_equal 1, Type::REAL <=> Type::INTEGRAL
      assert_equal 0, Type::REAL <=> Type::REAL
    end
  end
end