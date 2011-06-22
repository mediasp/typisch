require 'test/common'

describe "pretty printing" do

  it "registry should pretty-print to ruby code which evaluates to the same thing" do
    @registry = Registry.new
    @registry.register do
      register :bar, sequence(:bar)
      register :foo, tuple(:integer, :bar)
      register :baz, union(:string, object(:abc => :def))
      register :def, sequence(:baz)
      register :boo, :object do
        property :abc, tuple(:date, :time, :null, :complex, :real, :rational, :integer, :string)
        property :def, sequence(object(:foo => :integer, :bar => :integer))
        property :ghi, union(object(:foo => :integer), :string, sequence(object(:foo => :integer)))
        property :jkl, :forward
      end
      register :forward, sequence(:real)
    end

    # assert_pretty @registry.to_s

    full_circle = eval(@registry.to_s)

    @registry.types_by_name.each do |name,type|
      assert_equal @registry[name], full_circle[name]
    end
  end

end
