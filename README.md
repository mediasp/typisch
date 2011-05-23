# Typisch

A schema language / type system / validation framework, for semi-structured data and for data in dynamic languages.

The initial implementation is in Ruby, but the aim is that it be capable of describing data equally well in a range of dynamic languages
and semi-structured data serialization languages -- Ruby, Python, Javascript, YAML, JSON, ...

*N.B.* still a work in progress at this stage, but enough works that it may be interesting to poke around!

## What distinguishes it?

It aims to be more than just an ad-hoc data validation library; rather, a proper type system with formal foundations.

This means that it's able to do more than just validate data; it can settle questions phrased in terms of the
schemas themselves -- like "is this schema a subtype of this other schema?", or "compute the intersection of
these two schemas" -- in a well-defined and sound way.

This is nice, since if you're going to bother specifying a schema for your data at all (as opposed to just
writing some validation code), you're probably doing so because you want to be able to reason statically
about the structure of the data. Having solid foundations makes that easier and more pleasant.

## As a type system, it features

- Record types with structural subtyping
- Nominal subtyping based on a hierarchy of type tags (which can be based on the subclassing graph of the host language)
- Tagged union types (arbitrary untagged unions may be computed too, but some type information may be lost where the tags overlap)
- Equi-recursive types, eg "Person {parent: Person}", which can be used to type-check cyclic object graphs if required
- Parameterised polymorphic types for Sequences, Tuples and other collection types
- A numeric tower with subtyping for the primitive numeric types
- Refinement types like "Integer greater than 0", "String of at most 10 characters", "Float from the following set of allowed values" etc
- Decidable subtyping for all the above
- Ability to compute unions and intersections of types

If that sounds surprisingly powerful, bear in mind there's one very common type system feature which it *lacks*: function types, or typing
of code. Typisch only cares about typing data, which makes its life significantly easier.

Usually type systems for data are called 'schema languages', their types 'schemas', and type-checking 'validation'.
Forgive me if I use these terms somewhat interchangeably here.

## Semi-structured data and subtyping

One way to characterise semi-structured data would be: data whose datatype admits structural subtyping.

Structural subtyping allows extra fields beyond those specifically required, to be present on an object without cause for concern
-- as may frequently be the case with "duck-typed" data in dynamic languages, and data serialised in extensible schemas in formats
like JSON.

Sometimes you only care to validate, to serialize or to process a *subset* of a large structured object graph.
Structural typing provides a rather nice way to describe these subsets, as *supertypes* of the more complete datatype.

So, a good notion of subtyping seems useful for a type system designed to cope well with semi-structured data.

## Why Typisch?

Well, it combines Type and Schema. It's also german for "typical", as in "typical, another bloody schema language".