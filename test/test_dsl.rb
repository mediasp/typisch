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

      annotate "An integer or null", :some_other => 'annotation'
      annotate :and_another => 'annotation'
      register :nullable_integer, nullable(:integer)

      annotate :description => "A thing which people read", :some_other => 'annotation'
      register :book, :object do
        property :title, :string
        property :subtitle, union(:string, :null)
        property :author, :author
        property :things, map(:string, :integer)
      end

      annotate "Someone who writes a thing which people read"
      register :author, :object, AnAuthor do
        property :name, :string

        annotate "How old someone is"
        property :age,  :integer

        annotate :description => "The books they wrote", :special => 'special'
        property :books, sequence(:book)

        property(:favourite_cheese, :object) do
          property :smelliness, :real
        end

        property :numbers, sequence(:integer)
      end

      register :special_author, :derived_from, :author, ASpecialAuthor do
        derive_all_properties
        property :specialness, :integer
      end

      register :derived_author, :derived_from, :author do
        # this lets you derive multiple properties from the original type in one go
        # (but not customize them):
        derive_properties :name, :age

        # picking a derived type for the derived property works with sequence types too
        # - we want the books sequence, but with only the 'title' property on the books within it:
        derive_property :books do
          derive_property :title
        end

        # relax this to just a slice of the original sequence
        derive_property :numbers, :slice => 0...5
      end

      register :derived_book, :derived_from, :book do
        derive_property :title
        # recursively pick a derived version of author for the author property.
        # note we can't do this until after :author is registered; for now there
        # is a hard define-time dependency when using the derived_from DSL.
        derive_property :author do
          derive_property :age
        end
      end
    end

    assert_instance_of Type::Boolean, @registry[:alias_for_boolean]
    assert_equal "An integer or null", @registry[:nullable_integer].annotations[:description]
    assert_equal "annotation", @registry[:nullable_integer].annotations[:some_other]
    assert_equal "annotation", @registry[:nullable_integer].annotations[:and_another]

    assert_instance_of Type::Union, @registry[:nullable_integer]
    assert @registry[:nullable_integer].alternative_types.include?(@registry[:null])
    assert @registry[:nullable_integer].alternative_types.include?(@registry[:integer])

    book, author, special_author = @registry[:book], @registry[:author], @registry[:special_author]
    assert_instance_of Type::Object, book
    assert_instance_of Type::String, book[:title]
    assert_instance_of Type::Union,  book[:subtitle]
    assert_instance_of Type::String, book[:subtitle].alternative_types[0]
    assert_instance_of Type::Null,   book[:subtitle].alternative_types[1]

    assert_equal({:description => "A thing which people read", :some_other => 'annotation'}, book.annotations)

    assert_same book[:author], author
    assert_same author, book[:author]

    assert_equal("Someone who writes a thing which people read", author.annotations[:description])


    assert_equal AnAuthor, author.class_or_module
    assert_instance_of Type::String, author[:name]
    assert_instance_of Type::Numeric, author[:age]
    assert_instance_of Type::Sequence, author[:books]
    assert_instance_of Type::Object, author[:favourite_cheese]
    assert_instance_of Type::Numeric, author[:favourite_cheese][:smelliness]

    assert_equal({:description => "How old someone is"}, author.property_annotations(:age))
    assert_equal({:description => "The books they wrote", :special => 'special'}, author.property_annotations(:books))

    assert_same book, author[:books].type
    assert_same author[:books].type, book

    assert_instance_of Type::Map, book[:things]
    assert_instance_of Type::String, book[:things].key_type
    assert_instance_of Type::Numeric, book[:things].value_type

    assert_equal ASpecialAuthor, special_author.class_or_module
    assert_instance_of Type::String, special_author[:name]
    assert_same author[:favourite_cheese], special_author[:favourite_cheese]

    assert_instance_of Type::Numeric, special_author[:specialness]
    assert_nil author[:specialness]
    assert special_author < author


    derived_book = @registry[:derived_book]
    assert_instance_of Type::Object, derived_book
    assert_equal [:author, :title], derived_book.property_names.sort_by(&:to_s)
    assert_same derived_book[:title], book[:title]
    assert_equal [:age], derived_book[:author].property_names
    assert_equal AnAuthor, derived_book[:author].class_or_module

    derived_author = @registry[:derived_author]
    assert_instance_of Type::Object, derived_author
    assert_equal AnAuthor, derived_author.class_or_module
    assert_equal [:age, :books, :name, :numbers], derived_author.property_names.sort_by(&:to_s)
    assert_equal [:title], derived_author[:books].type.property_names
    assert_instance_of Type::Sequence, derived_author[:numbers]
    assert_equal 0...5, derived_author[:numbers].slice
  end

  class Unicorn < OpenStruct; end
  class Horn < OpenStruct; end

  it "should let you register types for particular classes (specifying a 'version' of that class which the type represents, defaulting to :main) and let you refer to them via the class (optionally with a :version => :foo parameter)" do
    @registry.register do
      register_type_for_class(Unicorn) do
        property :name, :string
        property :horn, Horn
      end

      register_version_type_for_class(Unicorn, :name_only) do
        property :name, :string
      end

      register_type_for_class(Horn) do
        property :length, :float
        property :unicorn, Unicorn
      end

      register_version_type_for_class(Horn, :unicorn_with_name_only) do
        property :length, :float
        property :unicorn, :Unicorn, :version => :name_only
      end
    end

    assert_same @registry[Horn], @registry[:Horn]
    assert_same @registry[Horn], @registry.types_by_class_and_version[Horn][:main]

    assert_same @registry[Horn, :unicorn_with_name_only], @registry[:Horn__unicorn_with_name_only]
    assert_same @registry[Horn, :unicorn_with_name_only], @registry.types_by_class_and_version[Horn][:unicorn_with_name_only]

    assert_same @registry[Horn][:unicorn], @registry[Unicorn]
    assert_same @registry[Horn, :unicorn_with_name_only][:unicorn], @registry[Unicorn, :name_only]

    refute_same @registry[Unicorn, :name_only], @registry[Unicorn]
  end

end
