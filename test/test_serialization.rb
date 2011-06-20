require 'test/common'
require 'typisch/serialization'
require 'ostruct'

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
          property :ghi, sequence(union(object(Zxc, :foo => :integer), :string, object(:bar => :string)))
          property :jkl, sequence(union(:integer, :null))
        end
      end
      @object = OpenStruct.new(
        :abc => [Date.new(2011,6,20), Time.utc(2011,6,20,21,6,12), nil, 1.23, 123, 'hello'],
        :def => [Vbn.new(:foo => 123, :bar => 456, :baz => "not included")],
        :ghi => [Zxc.new(:foo => 123), "string", Zxc.new(:bar => "hello")],
        :jkl => [1,nil,3],
        :baz => "not included"
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
          {"__class__"=>"Zxc", "bar"=>"hello"}
        ],
        "jkl" => [1, nil, 3]
      }
    end

    it "should let you customize the JSON property name / key used for type tags, and to customize the class to type tag mapping" do
      @serializer = JSONSerializer.new(@registry[:foo],
        :type_tag_key => 'DA_CLASS_IS',
        :class_to_type_tag => {Vbn => 'VeeBeeEn', Zxc => 'ZedExCee', OpenStruct => 'OpenSesame'}
      )
      jsonable = @serializer.serialize_to_jsonable(@object)

      assert_equal jsonable, {
        "DA_CLASS_IS" =>"OpenSesame",
        "abc"       => ["2011-06-20", "2011-06-20T21:06:12Z", nil, 1.23, 123, "hello"],
        "def"       => [{"DA_CLASS_IS"=>"VeeBeeEn", "foo"=>123, "bar"=>456}],
        "ghi"       => [
          {"DA_CLASS_IS"=>"ZedExCee", "foo"=>123},
          "string",
          {"DA_CLASS_IS"=>"ZedExCee", "bar"=>"hello"}
        ],
        "jkl" => [1, nil, 3]
      }
    end
  end

  # at present this is potentially a bit costly as it has to do a full type-check on
  # the remaining object graph before it can know for sure that it's picked the right
  # clause to serialize as, when serializing via an untagged union.
  #
  # I may ditch untagged unions and with them this behaviour - cost/benefit seems a bit
  # skewed.
  it "should serialize a union based on which clause it type-checks as" do
    @registry = Registry.new
    @registry.register do
      register :union, union(
        tuple(:integer, object(:foo => :string)),
        tuple(:string, object(:bar => :integer))
      )
    end
    @serializer = JSONSerializer.new(@registry[:union])

    jsonable = @serializer.serialize_to_jsonable([123, OpenStruct.new(:foo => 'hello', :bar => 123)])
    assert_equal jsonable, [123, {"__class__"=>"OpenStruct", "foo" => 'hello'}]

    jsonable = @serializer.serialize_to_jsonable(["string", OpenStruct.new(:foo => 'hello', :bar => 123)])
    assert_equal jsonable, ["string", {"__class__"=>"OpenStruct", "bar" => 123}]
  end
end
