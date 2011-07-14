# Typisch

A schema language / type system / validation framework, for semi-structured data and for data in dynamic languages.

The initial implementation is in Ruby, but the aim is that it be capable of describing data equally well in a range of dynamic languages
and semi-structured data serialization languages -- Ruby, Python, Javascript, YAML, JSON, ...

*N.B.* still a work in progress at this stage, but enough works that it may be interesting to poke around!

## What distinguishes it?

It aims to be more than just an ad-hoc data validation library; rather, a proper type system.

This means that it's able to do more than just validate data; it can settle questions phrased in terms of the
schemas themselves -- like "is this schema a subtype of this other schema?", or (on the roadmap) "compute the
intersection or union of these two schemas" -- in a well-defined and sound (*) way.

This is nice, since if you're going to bother specifying types for your data (as opposed to just writing
some validation code), you're probably doing so because you want to be able to reason statically about the
structure of the data. Having solid foundations makes that easier and more pleasant.

(*Sound with respect to an idealised data interchange language; in ruby there may be some minor differences:
sometimes ruby fails to distinguish between representations of two types, eg Tuple vs Sequence;
sometimes ruby draws ruby-specific implementation distinctions, eg Time vs DateTime or String vs
Symbol, which the Typisch types not to care about)

## As a type system, it features

- Record types with structural subtyping, and nominal subtyping based on a hierarchy of type tags (which
  in ruby is based on the subclassing / module inclusion graph)
- Tagged union types (support for untagged unions was experimented with and may return to the roadmap at some stage)
- Equi-recursive types, eg `Person {parent: Person}`, which can be used to type-check cyclic object graphs if required
- Parameterised polymorphic types for Sequences, Tuples and other collection types
- A numeric tower with subtyping for the primitive numeric types
- Refinement types like "String of at most 10 characters", "String from the following set of allowed values" etc, with more to come
- Decidable subtyping and type-checking for all the above

If that sounds powerful, bear in mind there's one very common type system feature which it *lacks*: function types, or typing
of code. Typisch only cares about typing data, which makes its life significantly easier.

Usually type systems for data are called 'schema languages', their types 'schemas', and type-checking 'validation'.

## Semi-structured data and subtyping

One way to characterise semi-structured data would be: data whose datatype admits structural subtyping.

Structural subtyping allows extra fields beyond those specifically required, to be present on an object without cause for concern
-- as may frequently be the case with "duck-typed" data in dynamic languages, and data serialised in extensible schemas in formats
like JSON.

Sometimes you only care to validate, to serialize or to process a *subset* of a large structured object graph.
Structural typing provides a rather nice way to describe these subsets, as *supertypes* of the more complete datatype.

So, a good notion of subtyping seems useful for a type system designed to cope well with semi-structured data.

## Type-directed (partial) serialization

A big part of the motivation is to support type-directed serialization into data interchange languages like JSON,
YAML, XML etc.

A deficiency in many serialization frameworks is the lack of support for flexible customization of the depth to which a
large object graph is serialized, and the shape such a partial serialization takes. Eg one may want:

- Different 'versions' of the same object which include or ommit different subsets of its properties
- Different versions of sub-objects to be used within a parent object, including when they appear within sequences, unions etc
- Just a particular slice (eg the first 10 items) of a large sequence of objects to be serialized

Typisch supports all these and more, via structural supertypes for object types, *and* for sequence types.
Structural supertypes for sequences are 'slice types', specifying serialization and/or type-checking of
only a particular slice of a sequence.

At present there is only basic support for serialization to JSON, and some details which are not part of the
JSON spec (like how type tags are serialized) need to be configured.

When serializing in JSON you need to avoid using unlimited recursion depth in the types and values being
serialized, as JSON doesn't support cyclic references.

Support for YAML would be nice to add, which provides better support for type tags, and for serializing cyclic
structures natively.

XML would be nice too, although would probably require more configuration for mapping, as its markup-based data model
isn't as close to that of Typisch and most dynamic languages.

Further down the roadmap, there is a lot of potential to compile fast serialization code (in Ruby, Java, C?) from a
particular type.

## Why Typisch?

Well, it combines Type and Schema. It's also german for "typical", as in "typical, another bloody schema language".
