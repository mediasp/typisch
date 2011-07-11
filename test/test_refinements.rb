require 'test/common'

describe "refinement types" do
  before {@registry = Registry.new}

  it "should allow refinement types of String specifying an allowed set of values, or a max_length, or both" do
    @registry.register do
      register :long, string(:max_length => 10)
      register :short, string(:max_length => 5)
      register :ab, string(:values => ['a','b'])
      register :b, string(:values => ['b'])
    end

    assert @registry[:short] < @registry[:long]
    assert @registry[:long] < @registry[:string]

    assert @registry[:b] < @registry[:ab]
    assert @registry[:ab] < @registry[:string]

    assert @registry[:string] === 'abcde'
    assert @registry[:short] === 'abcde'
    refute @registry[:short] === 'abcdef'
    assert @registry[:long] === 'abcdef'
    refute @registry[:long] === 'abcdefghjkl'

    assert @registry[:ab] === 'a'
    assert @registry[:ab] === 'b'
    refute @registry[:ab] === 'c'
    refute @registry[:b] === 'a'
    assert @registry[:b] === 'b'
  end
end
