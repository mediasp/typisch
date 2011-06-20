require 'test/common'

describe "Type#recursive?" do

  before do
    @registry = Registry.new
  end

  it "should return false for a type which makes no use of recursion" do

    @registry.register do
      register :foo, :object do
        property :abc, tuple(:date, :time, :null, :complex, :real, :rational, :integer, :string)
        property :def, sequence(object(:foo => :integer, :bar => :integer))
        property :ghi, union(object(:foo => :integer), :string, sequence(object(:foo => :integer)))
        property :jkl, :forward
      end
      register :forward, sequence(:real)
    end

    assert_false @registry[:foo].recursive?
    assert_false @registry[:foo][:abc].recursive?
    assert_false @registry[:foo][:def].recursive?
    assert_false @registry[:foo][:ghi].recursive?
    assert_false @registry[:forward].recursive?
  end

  it "should return true for any type which uses recursion at any point" do
    @registry.register do
      register :bar, sequence(:bar)
      register :foo, tuple(:integer, :bar)
      register :baz, union(:string, object(:abc => :def))
      register :def, sequence(:baz)
    end
    assert @registry[:bar].recursive?
    assert @registry[:foo].recursive?
    assert @registry[:baz].recursive?
    assert @registry[:def].recursive?
  end
end
