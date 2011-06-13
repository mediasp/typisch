require 'test/common'

describe "Sequence types" do
  before do
    @types = Registry.new
  end

  it "should subtype covariantly in the argument type" do
    assert_operator Type::Sequence.new(@types[:integer]), :<, Type::Sequence.new(@types[:real])
    assert_equal Type::Sequence.new(@types[:integer]), Type::Sequence.new(@types[:integer])
    refute_operator Type::Sequence.new(@types[:real]), :<, Type::Sequence.new(@types[:integer])
  end

  it "should compute equality successfully for a recursive type (ie cyclic graph of types)" do
    # todo: less cludgey way of wiring up these cyclic object graphs
    recursive = Type::Sequence.allocate
    recursive.send(:initialize, recursive)

    assert_equal recursive, recursive
  end

  it "should equate bisimilar cyclic type graphs" do
    recursive = Type::Sequence.allocate
    recursive.send(:initialize, recursive)

    recursive2 = Type::Sequence.new(recursive)

    recursive3, recursive4 = Type::Sequence.allocate, Type::Sequence.allocate
    recursive3.send(:initialize, recursive4)
    recursive4.send(:initialize, recursive3)

    assert_equal recursive, recursive2
    assert_equal recursive2, recursive
    assert_equal recursive, recursive3
    assert_equal recursive2, recursive3
    assert_equal recursive3, recursive4

    refute_equal recursive, Type::Sequence.new(@types[:null])
  end
end
