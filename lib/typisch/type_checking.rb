class Typisch::Type

  # This uses essentially the same corecursive algorithm used for subtyping.
  # Just this time we're comparing with a possible instance rather than a possible
  # subtype.
  def ===(instance, already_checked={})
    return true if already_checked[[self, instance]]
    already_checked[[self, instance]] = true
    check_type(instance) {|u,v| u.===(v, already_checked)}
  end

end
