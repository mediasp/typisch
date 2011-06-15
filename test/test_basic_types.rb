require 'test/common'

describe "basic Type::Constructor subclasses (Boolean, Null, Numeric, ...)" do

  before do
    @registry = Registry.new
    [:boolean, :null, :complex, :real, :rational, :integer, :date, :time, :string].each do |t|
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
    it "should be arranged in a linear subtyping order: Integral < Rational < Real < Complex" do
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

    it "should type-check integer correctly" do
      assert @integer === 123
      assert @integer === 12334567346574365783465734856
      refute @integer === nil
      refute @integer === Rational(1,1)
      refute @integer === Rational(1,2)
      refute @integer === 12.34
      refute @integer === 12.00
      refute @integer === BigDecimal('12.23')
      refute @integer === Complex(1,0)
      refute @integer === Complex(1,2)
    end

    it "should type-check rational correctly" do
      assert @rational === 123
      assert @rational === 12334567346574365783465734856
      assert @rational === Rational(1,1)
      assert @rational === Rational(1,2)
      refute @rational === nil
      refute @rational === 12.34
      refute @rational === 12.00
      refute @rational === BigDecimal('12.23')
      refute @rational === Complex(1,0)
      refute @rational === Complex(1,2)
    end

    it "should type-check real correctly" do
      assert @real === 123
      assert @real === 12334567346574365783465734856
      assert @real === Rational(1,1)
      assert @real === Rational(1,2)
      assert @real === 12.34
      assert @real === 12.00
      assert @real === BigDecimal('12.23')
      refute @real === nil
      refute @real === Complex(1,0)
      refute @real === Complex(1,2)
    end

    it "should type-check complex correctly" do
      assert @complex === 123
      assert @complex === 12334567346574365783465734856
      assert @complex === Rational(1,1)
      assert @complex === Rational(1,2)
      assert @complex === 12.34
      assert @complex === 12.00
      assert @complex === BigDecimal('12.23')
      assert @complex === Complex(1,0)
      assert @complex === Complex(1,2)
      refute @complex === nil
    end

    it "should type-check Null correctly" do
      assert @null === nil
      refute @null === false
      refute @null === 0
      refute @null === ''
    end

    it "should type-check Boolean correctly" do
      assert @boolean === true
      assert @boolean === false
      refute @boolean === nil
      refute @boolean === ''
      refute @boolean === 0
      refute @boolean === 1
    end

    it "should type-check String correctly" do
      assert @string === 'foo'
      assert @string === ''
      refute @string === nil
      refute @string === true
      refute @string === 0
      refute @string === 1
    end

    it "should type-check Date correctly" do
      assert @date === Date.today
      refute @date === Time.now
      refute @date === nil
      refute @date === true
      refute @date === 0
      refute @date === 1
    end

    it "should type-check Time correctly" do
      assert @time === Time.now
      refute @time === Date.today
      refute @time === nil
      refute @time === true
      refute @time === 0
      refute @time === 1
    end


  end
end
