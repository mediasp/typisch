require 'test/common'

# namespace this so the class and module constants we define don't leak into other tests
module TestDAG

  # easiest way to get a poset in ruby is to set up an inheritance/inclusion hierarchy of
  # classes and modules, which respond to <=, <, >, >= etc
  module A; end
  module B; end
  class C; include A; end
  class D; include A; include B; end
  class E; include B; end

  class F < E; end

  class G; end

  module H; end
  class I < F; include H; end
  class J; include H; end

  describe "find_minimal_set_of_upper_bounds" do

    def assert_same_items(expected, result)
      assert_equal expected.sort_by(&:name), result.sort_by(&:name)
    end

    it "should return just the upper bound of a chain" do
      assert_same_items [E], Typisch.find_minimal_set_of_upper_bounds(E, F)
      assert_same_items [E], Typisch.find_minimal_set_of_upper_bounds(F, E)
      assert_same_items [E], Typisch.find_minimal_set_of_upper_bounds(E, F, I)
    end

    it "should return just the top of a tree" do
      assert_same_items [B], Typisch.find_minimal_set_of_upper_bounds(B, D, E, F)
      assert_same_items [B], Typisch.find_minimal_set_of_upper_bounds(D, E, F, B)
    end

    it "should return both upper bounds even if they have a common child" do
      assert_same_items [A, B], Typisch.find_minimal_set_of_upper_bounds(A, B, D)
      assert_same_items [A, B], Typisch.find_minimal_set_of_upper_bounds(A, D, B)
      assert_same_items [A, B], Typisch.find_minimal_set_of_upper_bounds(D, A, B)
    end

    it "should keep two trees separate" do
      assert_same_items [A, B], Typisch.find_minimal_set_of_upper_bounds(A, B, C, D, E)
    end

    it "should behave as expected on a non-trivial example DAG, regardless of the order the set is given in" do
      100.times do
        items = [A, B, C, D, E, F, G, H, I, J].shuffle
        result = Typisch.find_minimal_set_of_upper_bounds(*items)
        assert_same_items [A, B, G, H], result
      end
    end
  end
end
