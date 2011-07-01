require 'test/common'

describe "Registry#register / DSLContext" do

  before do
    @registry = Registry.new
  end

  class AnAuthor < OpenStruct; end
  class ASpecialAuthor < AnAuthor; end

  # todo: some more fine-grained specs for how this works
  it "should let you create and register types using some nice syntax" do
    @registry.register do
      register :alias_for_boolean, :boolean

      register :nullable_integer, nullable(:integer)

      register :book, :object do
        property :title, :string
        property :subtitle, union(:string, :null)
        property :author, :author
      end

      register :author, :object, AnAuthor do
        property :name, :string
        property :age,  :integer
        property :books, sequence(:book)
        property(:favourite_cheese, :object) do
          property :smelliness, :real
        end
      end

      register :special_author, :object_subtype, :author, ASpecialAuthor do
        property :specialness, :integer
      end
    end

    assert_instance_of Type::Boolean, @registry[:alias_for_boolean]

    assert_instance_of Type::Union, @registry[:nullable_integer]
    assert @registry[:nullable_integer].alternative_types.include?(@registry[:null])
    assert @registry[:nullable_integer].alternative_types.include?(@registry[:integer])

    book, author, special_author = @registry[:book], @registry[:author], @registry[:special_author]
    assert_instance_of Type::Object, book
    assert_instance_of Type::String, book[:title]
    assert_instance_of Type::Union,  book[:subtitle]
    assert_instance_of Type::String, book[:subtitle].alternative_types[0]
    assert_instance_of Type::Null,   book[:subtitle].alternative_types[1]

    assert_same book[:author], author
    assert_same author, book[:author]


    assert_equal AnAuthor, author.class_or_module
    assert_instance_of Type::String, author[:name]
    assert_instance_of Type::Numeric, author[:age]
    assert_instance_of Type::Sequence, author[:books]
    assert_instance_of Type::Object, author[:favourite_cheese]
    assert_instance_of Type::Numeric, author[:favourite_cheese][:smelliness]

    assert_same book, author[:books].type
    assert_same author[:books].type, book

    assert_equal ASpecialAuthor, special_author.class_or_module
    assert_instance_of Type::String, special_author[:name]
    assert_same author[:favourite_cheese], special_author[:favourite_cheese]

    assert_instance_of Type::Numeric, special_author[:specialness]
    assert_nil author[:specialness]

    assert special_author < author
  end
end
