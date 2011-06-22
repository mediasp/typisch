require 'minitest/spec'
require 'minitest/autorun'

require 'typisch'
include Typisch

require 'ostruct'

module MiniTest::Assertions
  def assert_false obj, msg = nil
    msg = message(msg) { "Expected #{mu_pp(obj)} to be false" }
    assert false == obj, msg
  end
end

# Some classes and modules for testing with
class TestClass; end
module TestModule; end
class TestSubclass < TestClass; include TestModule; end
class TestClass2; include TestModule; end
