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

  require 'set'
  it "should typecheck correctly" do
    seq = Type::Sequence.new(@types[:boolean])
    assert seq === []
    assert seq === [true]
    assert seq === [false, true, false]
    assert seq === Set.new([true, false])
    assert seq === [true, false].to_enum

    refute seq === [1]
    refute seq === [true, 1]
    refute seq === [1, true]
  end

  it "should typecheck cyclic instances against cyclic types" do
    seq = Type::Sequence.allocate
    seq.send(:initialize, seq)
    instance = []; instance << instance
    assert seq === instance

    seq2 = Type::Sequence.allocate
    seq2.send(:initialize, Type::Sequence.new(seq2))
    assert seq2 === instance

    instance = [[]]; instance[0] << instance
    assert seq === instance
    assert seq2 === instance

    instance[0] << 123
    refute seq === instance
    refute seq2 === instance

    # some with the cyclic type against a non-cyclic but quite deep instance
    # ('sequence of sequence of sequence of ...')
    assert seq === [[],[[],[[]],[]],[[[[],[]],[]]],[[]]]
    assert seq2 === [[],[[],[[]],[]],[[[[],[]],[]]],[[]]]
  end

  it "should type-check a Hash as a sequence of tuples" do
    map_type = Type::Sequence.new(Type::Tuple.new(@types[:string], @types[:integer]))
    assert map_type === {}
    assert map_type === {"foo" => 123}
    assert map_type === {"foo" => 123, "bar" => 456}
    refute map_type === {"foo" => 123, "bar" => nil}
    refute map_type === {Object.new => 123, "bar" => 456}
  end
end
