class Typisch::Type

  # This uses essentially the same corecursive backtracking
  # algorithm used for subtyping. Just this time we're comparing
  # with a possible instance rather than a possible subtype.
  def ===(instance, already_checked={})
    return true if already_checked[[self, instance]]

    shadow_already_checked = Hash.new {|h,k| already_checked[k]}
    shadow_already_checked[[self, instance]] = true

    result = check_type(instance) {|u,v| u.===(v, shadow_already_checked)}

    already_checked.merge!(shadow_already_checked) if result
    result
  end

end
