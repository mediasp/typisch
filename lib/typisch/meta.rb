module Typisch
  META_TYPES = Registry.new
  META_TYPES.register do

    register(:"Typisch::Type", :union,
      :"Typisch::Type::String",
      :"Typisch::Type::Numeric",
      :"Typisch::Type::Boolean",
      :"Typisch::Type::Null",
      :"Typisch::Type::Date",
      :"Typisch::Type::Time",
      :"Typisch::Type::Object",
      :"Typisch::Type::Sequence",
      :"Typisch::Type::Tuple",
      :"Typisch::Type::Union"
    )

    register_type_for_class(Type::Boolean)
    register_type_for_class(Type::Null)
    register_type_for_class(Type::Date)
    register_type_for_class(Type::Time)

    register_type_for_class(Type::Numeric) do
      property :tag, :string
    end

    register_type_for_class(Type::String) do
      property :values,     nullable(sequence(:string))
      property :max_length, nullable(:integer)
    end

    register_type_for_class(::Range) do
      property :begin, :integer
      property :end,   :integer
    end

    register_type_for_class(Type::Sequence) do
      property :type,         :"Typisch::Type"
      property :slice,        nullable(:Range)
      property :total_length, nullable(:boolean)
    end

    register_type_for_class(Type::Tuple) do
      property :name, :string
      property :types, sequence(:"Typisch::Type")
    end

    register_type_for_class(Type::Object) do
      property :property_names_to_types, map(:string, :"Typisch::Type")
      property :tag, :string
      property :version, nullable(:string)
    end

    register_type_for_class(Type::Union) do
      property :alternative_types, sequence(:"Typisch::Type")
    end
  end

end
