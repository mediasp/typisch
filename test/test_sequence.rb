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

  it "should typecheck arrays correctly as basic sequence types" do
    seq = Type::Sequence.new(@types[:boolean])
    assert seq === []
    assert seq === [true]
    assert seq === [false, true, false]

    refute seq === [1]
    refute seq === [true, 1]
    refute seq === [1, true]
    refute seq === "not a sequence, not really"
    refute seq === nil
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


  it "should subtype slice types correctly" do
    noslice = Type::Sequence.new(@types[:integer])
    assert_operator noslice, :<, Type::Sequence.new(@types[:integer], :slice => 0...10)
    assert_operator noslice, :<, Type::Sequence.new(@types[:integer], :slice => 5...15)
    assert_operator Type::Sequence.new(@types[:integer], :slice => 0...20), :<, Type::Sequence.new(@types[:integer], :slice => 0...10)
    assert_operator Type::Sequence.new(@types[:integer], :slice => 5...15), :<, Type::Sequence.new(@types[:integer], :slice => 10...12)
    assert_operator Type::Sequence.new(@types[:integer], :slice => 5...15), :<, Type::Sequence.new(@types[:integer], :slice => 5...14)
    assert_operator Type::Sequence.new(@types[:integer], :slice => 5...15), :<, Type::Sequence.new(@types[:integer], :slice => 6...15)
    assert_nil Type::Sequence.new(@types[:integer], :slice => 5...15) <=> Type::Sequence.new(@types[:integer], :slice => 4...14)

    assert_operator Type::Sequence.new(@types[:integer], :slice => 5...15, :total_length => true), :<,
                    Type::Sequence.new(@types[:integer], :slice => 5...15, :total_length => false)

    assert_operator Type::Sequence.new(@types[:integer], :slice => 5...15, :total_length => false), :==,
                    Type::Sequence.new(@types[:integer], :slice => 5...15, :total_length => false)

    refute_operator Type::Sequence.new(@types[:integer], :slice => 5...15, :total_length => false), :<=,
                    Type::Sequence.new(@types[:integer], :slice => 5...15, :total_length => true)
  end

  it "should type-check slice types correctly, only checking items in the specified slice, and not checking the length if total_length is false" do
    slice = Type::Sequence.new(@types[:integer], :slice => 1...3)
    assert slice === []
    assert slice === [nil, 1]
    assert slice === [nil, 1, 2]
    assert slice === [nil, 1, 2, 3]
    assert slice === [nil, 1, 2, nil]
    refute slice === [nil, nil, 2, nil]
    refute slice === [nil, 1, nil, nil]
    refute slice === [nil, nil, nil, nil]

    lengthless = []
    lengthless.expects(:length => nil)
    refute slice === lengthless

    lengthless_slice = Type::Sequence.new(@types[:integer], :slice => 1...3, :total_length => false)
    assert lengthless_slice === lengthless
  end

  it "should allow map(x,y) as a special alias for sequence(tuple(x,y))" do
    map = Type::Map.new(@types[:string], @types[:integer])
    assert_equal map, Type::Sequence.new(Type::Tuple.new(@types[:string], @types[:integer]))
  end
end
