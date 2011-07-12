require 'test/common'
require 'typisch/serialization'

describe "JSONSerializer" do

  class Zxc < OpenStruct; end
  class Vbn < OpenStruct; end

  describe "example" do

    before do
      @registry = Registry.new
      @registry.register do
        register :foo, :object do
          property :abc, tuple(:date, :time, :null, :real, :integer, :string)
          property :def, sequence(object(Vbn, :foo => :integer, :bar => :integer))
          property :ghi, sequence(union(object(Zxc, :foo => :integer), :string, object(Vbn, :bar => :integer)))
          property :jkl, sequence(union(:integer, :null))
          property :boz, sequence(:integer, :slice => 1...3)
          property :buz, sequence(:integer, :slice => 2...100, :total_length => false)
          property :biz, sequence(:integer, :slice => 100...200)
        end
      end
      @object = OpenStruct.new(
        :abc => [Date.new(2011,6,20), Time.utc(2011,6,20,21,6,12), nil, 1.23, 123, 'hello'],
        :def => [Vbn.new(:foo => 123, :bar => 456, :baz => "not included")],
        :ghi => [Zxc.new(:foo => 123), "string", Vbn.new(:bar => 456)],
        :jkl => [1,nil,3],
        :baz => "not included",
        :boz => [0,1,2,3,4],
        :buz => [0,1,2,3,4],
        :biz => [0,1,2,3,4]
      )
    end


    it "should serialize data directed by a type, only including in the serialization structural features of the data which the type refers to" do
      @serializer = JSONSerializer.new(@registry[:foo])
      jsonable = @serializer.serialize_to_jsonable(@object)

      assert_equal jsonable, {
        "__class__" =>"OpenStruct",
        "abc"       => ["2011-06-20", "2011-06-20T21:06:12Z", nil, 1.23, 123, "hello"],
        "def"       => [{"__class__"=>"Vbn", "foo"=>123, "bar"=>456}],
        "ghi"       => [
          {"__class__"=>"Zxc", "foo"=>123},
          "string",
          {"__class__"=>"Vbn", "bar"=>456}
        ],
        "jkl" => [1, nil, 3],
        "boz" => {
          "__class__" => "Array",
          "range_start" => 1,
          "total_items" => 5,
          "items" => [1,2]
        },
        "buz" => {
          "__class__" => "Array",
          "range_start" => 2,
          "items" => [2,3,4]
        },
        "biz" => {
          "__class__" => "Array",
          "range_start" => 100,
          "total_items" => 5
        }
      }
    end

    it "should let you customize the JSON property name / key used for type tags, and to customize the class to type tag mapping" do
      @serializer = JSONSerializer.new(@registry[:foo],
        :type_tag_key => 'DA_CLASS_IS',
        :class_to_type_tag => {Vbn => 'VeeBeeEn', Zxc => 'ZedExCee', OpenStruct => 'OpenSesame', Array => 'seq'}
      )
      jsonable = @serializer.serialize_to_jsonable(@object)

      assert_equal jsonable, {
        "DA_CLASS_IS" =>"OpenSesame",
        "abc"       => ["2011-06-20", "2011-06-20T21:06:12Z", nil, 1.23, 123, "hello"],
        "def"       => [{"DA_CLASS_IS"=>"VeeBeeEn", "foo"=>123, "bar"=>456}],
        "ghi"       => [
          {"DA_CLASS_IS"=>"ZedExCee", "foo"=>123},
          "string",
          {"DA_CLASS_IS"=>"VeeBeeEn", "bar"=>456}
        ],
        "jkl" => [1, nil, 3],
        "boz" => {
          "DA_CLASS_IS" => "seq",
          "range_start" => 1,
          "total_items" => 5,
          "items" => [1,2]
        },
        "buz" => {
          "DA_CLASS_IS" => "seq",
          "range_start" => 2,
          "items" => [2,3,4]
        },
        "biz" => {
          "DA_CLASS_IS" => "seq",
          "range_start" => 100,
          "total_items" => 5
        }
      }
    end
  end

  it "should serialize a tagged union based on which clause its tag matches (and complain if it doesn't match any)" do
    @registry = Registry.new
    @registry.register do
      register :union, union(
        object(Zxc, :foo => :string),
        object(Vbn, :bar => :integer)
      )
    end
    @serializer = JSONSerializer.new(@registry[:union])

    jsonable = @serializer.serialize_to_jsonable(Zxc.new(:foo => 'hello'))
    assert_equal jsonable, {"__class__"=>"Zxc", "foo" => 'hello'}

    jsonable = @serializer.serialize_to_jsonable(Vbn.new(:bar => 123))
    assert_equal jsonable, {"__class__"=>"Vbn", "bar" => 123}

    assert_raises(SerializationError) do
      @serializer.serialize_to_jsonable(OpenStruct.new(:bar => 123))
    end
  end
end
