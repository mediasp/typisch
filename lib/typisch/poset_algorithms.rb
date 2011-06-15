module Typisch

  class << self
    # Finds a minimal set of upper bounds amongst the given set of items
    # from a partially-ordered set, which together cover the whole set.
    #
    # In the worst case this will just return the whole set.
    def find_minimal_set_of_upper_bounds(*items)
      result = []
      items.each do |item|
        next if result.any? {|other| item <= other}
        result.delete_if {|other| other <= item}
        result << item
      end
      result
    end
  end
end
