class Typisch::Type
  class << self
    # The core of the subtyping algorithm, which copes with equi-recursive types.
    #
    # Actually quite simple on the face of it -- or at least, short.
    #
    # The crucial thing is that we allow a goal to be assumed without proof during
    # the proving of its subgoals. Since (because of the potentially recursive nature
    # of types) those subgoals may refer to types from the parent goal, we could otherwise
    # run into infinite loops.
    #
    # How's that justified from a logic perspective? well, what we're doing is,
    # we're just checking that the given subtyping judgement *isn't* provably
    # *false* under the inference rules at hand. This allows a maximal consistent
    # set of subtyping judgements to be made.
    #
    # Its dual, requiring that the judgement *is* provably *true* under the inference
    # rules, would only allow a minimal set to be proven, and could get stuck
    # searching forever for a proof of those judgements which are neither provably false
    # nor provably true (namely, the awkward recursive ones).
    #
    # See Pierce on equi-recursive types and subtyping for the theory:
    # http://www.cis.upenn.edu/~bcpierce/tapl/, it's an application of
    # http://en.wikipedia.org/wiki/Knaster–Tarski_theorem to show that this
    # is a least fixed point with respect to the adding of extra inferences
    # to a set of subtyping judgements, if you note that those inference rules
    # are monotonic. 'Corecursion' / 'coinduction' are also terms for what's
    # going on here.
    #
    # TODO: for best performance, should we be going depth-first or breadth-first here?
    #
    # Also TODO: when subtype? succeeds (returns true), we can safely save the resulting
    # set of judgements that were shown to be consistent, for use during future calls to
    # subtype?. Memoization essentially.
    def subtype?(x, y, may_assume_proven = {}, depth=0)
#      puts "#{'  '*depth}Testing #{x.inspect} <= #{y.inspect}"
#      puts "#{'  '*depth}#{may_assume_proven.length} Given assumptions"
#      may_assume_proven.each_key {|a,b| puts "  #{'  '*depth}#{a.inspect} <= #{b.inspect}"}

      if may_assume_proven[[x,y]]
#        puts "#{'  '*depth}Was true by assumption\n\n"
        return true
      else
#        puts "#{'  '*depth}Wasn't already assumable proven, checking subgoals where necessary:"
      end

#      puts "#{'  '*depth}Creating shadow lookup of subtype judgements with the one in progress added to it, to pass on for subgoals"
      shadow_may_assume_proven = Hash.new {|h,k| may_assume_proven[k]}
      shadow_may_assume_proven[[x,y]] = true

      result = check_subtype(x, y) do |u,v|
        subtype?(u, v, shadow_may_assume_proven, depth+1)
      end

      if result
#        puts "#{'  '*depth}Checking of subgoals succeeded, committing #{shadow_may_assume_proven.length} subtype judgements which were demonstrated in the process\n\n"
        may_assume_proven.merge!(shadow_may_assume_proven)
      else
#        puts "#{'  '*depth}Checking of subgoals failed, throwing away #{shadow_may_assume_proven.length} subtype judgements which had accumulated\n\n"
      end
      result
    end

  private
    def check_subtype(x, y, &recursively_check_subtype)
      # Types are either union types, or tagged types. We deal with the unions first.
      if Union === x
        x.alternative_types.all? {|t| recursively_check_subtype[t, y]}
      elsif Union === y
        y.alternative_types.any? {|t| recursively_check_subtype[x, t]}
      elsif x.class == y.class
        # Hand over to that specific Type::Tagged subclass in order to check subtyping
        # goals which are specific to its subtype lattice.
        x.class.check_subtype(x, y, &recursively_check_subtype)
      else
        # Different Type::Tagged subclasses are assumed non-overlapping, so we stop unless they're
        # the same:
        false
      end
    end
  end
end
