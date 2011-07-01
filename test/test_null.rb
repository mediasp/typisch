require 'test/common'

describe "excluding_null" do

  before do
    @registry = Registry.new
  end

  it "should return self for most types which don't permit null" do
    assert_same @registry[:string], @registry[:string].excluding_null
    assert_same @registry[:integer], @registry[:integer].excluding_null
  end

  it "should return 'nothing' from 'null'" do
    assert_same @registry[:nothing], @registry[:null].excluding_null
  end

  it "should return x from union(x, :null)" do
    assert_same @registry[:integer], Type::Union.new(@registry[:integer], @registry[:null]).excluding_null
    assert_same @registry[:integer], Type::Union.new(@registry[:null], @registry[:integer]).excluding_null
  end

  it "should return union(x, y) from union(x, y, null)" do
    assert_equal Type::Union.new(@registry[:integer], @registry[:string]),
      Type::Union.new(@registry[:integer], @registry[:string], @registry[:null]).excluding_null

    assert_equal Type::Union.new(@registry[:integer], @registry[:string]),
      Type::Union.new(@registry[:integer], @registry[:null], @registry[:string]).excluding_null

    assert_equal Type::Union.new(@registry[:integer], @registry[:string]),
      Type::Union.new(@registry[:null], @registry[:string], @registry[:integer]).excluding_null
  end
end
