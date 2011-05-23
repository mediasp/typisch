require 'minitest/spec'
require 'minitest/autorun'

require 'typisch'
include Typisch

module MiniTest::Assertions
  def assert_false obj, msg = nil
    msg = message(msg) { "Expected #{mu_pp(obj)} to be false" }
    assert false == obj, msg
  end
end