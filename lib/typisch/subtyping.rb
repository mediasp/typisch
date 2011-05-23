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
    # are monotonic.
    #
    # TODO: for best performance, should we be going depth-first or breadth-first here?
    #
    # Also TODO: when subtype? succeeds (returns true), we can safely save the resulting
    # set of judgements that were shown to be consistent, for use during future calls to
    # subtype?. Memoization essentially.  
    def subtype?(x, y)
      remaining_goals = [[x,y]]
      may_assume_proven = {}

      while (goal = remaining_goals.pop)
        next if may_assume_proven[goal]

        subgoals = subgoals_to_prove_subtype(*goal)
        return false unless subgoals

        may_assume_proven[goal] = true
        remaining_goals.push(*subgoals)
      end

      return true
    end
  
  private
    def subgoals_to_prove_subtype(x, y)
      # Types are either union types, or tagged types. We deal with the unions first.
      if Union === x || Union === y
        # To prove that a union x is a subtype of a union y, for each alternative tagged type in x
        # we have to find a type in y which it can be a subtype of.
        #
        # Since there's no overlap between different Type::Tagged subclasses, we know we
        # need to find a type of the same class for there to be a chance of showing this;
        # if we find more than one type of that class though, we ask the class to pick
        # one of them for us to proceed with as a goal. If it can't find one, we bail on
        # the whole operation.
        #
        # (note: even if only one of x or y is a union, the other will still expose a union-like
        #  interface as a union with only one type, itself, in alternative_types)
        return x.alternative_types.map do |type_in_x|
          types_in_y_of_same_class = y.alternative_types_by_class[type_in_x.class] or return false
          type_in_x.class.pick_subtype_goal_from_alternatives_in_union(
            type_in_x, types_in_y_of_same_class) or return false
        end
      end

      # So now we definitely have two Type::Tagged types.
      #
      # Different Type::Tagged subclasses are assumed non-overlapping, so we stop unless they're
      # the same:
      return false unless x.class == y.class
      # Now we hand over to that specific Type::Tagged subclass in order to give us any subtyping
      # goals which are specific to its subtype lattice.
      x.class.subgoals_to_prove_subtype(x, y)
    end
  end
end