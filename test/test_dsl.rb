require 'test/common'

describe "Registry#register / DSLContext" do

  before do
    @registry = Registry.new
  end

  # todo: some more fine-grained specs for how this works
  it "should let you create and register types using some nice syntax" do
    @registry.register do
      register :alias_for_boolean, :boolean

      register :book, :object do
        property :title, :string
        property :subtitle, union(:string, :null)
        property :author, :author
      end

      register :author, :object do
        property :name, :string
        property :age,  :integer
        property :books, sequence(:book)
        property(:favourite_cheese, :object) do
          property :smelliness, :real
        end
      end
    end

    assert_instance_of Type::Boolean, @registry[:alias_for_boolean]

    book, author = @registry[:book], @registry[:author]
    assert_instance_of Type::Object, book
    assert_instance_of Type::String, book[:title]
    assert_instance_of Type::Union,  book[:subtitle]
    assert_instance_of Type::String, book[:subtitle].alternative_types[0]
    assert_instance_of Type::Null,   book[:subtitle].alternative_types[1]

    # todo: make these assert_same once we have type graph canonicalization in place
    assert_equal book[:author], author
    assert_equal author, book[:author]


    assert_instance_of Type::String, author[:name]
    assert_instance_of Type::Numeric, author[:age]
    assert_instance_of Type::Sequence, author[:books]
    assert_instance_of Type::Object, author[:favourite_cheese]
    assert_instance_of Type::Numeric, author[:favourite_cheese][:smelliness]

    # todo: make these assert_same once we have type graph canonicalization in place
    assert_equal book, author[:books].type
    assert_equal author[:books].type, book
  end
end
