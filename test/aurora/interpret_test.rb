require 'test/unit'
require 'aurora-sdk'
require_relative '../test_helpers'

class InterpretTest < Test::Unit::TestCase
    include TestHelpers

    def test_create_interpret
        test_text = "Alpha"
        test_intent = "beta"
        test_entities = ['charlie', 'delta']

        interpret = Aurora::Interpret.new(test_text, test_intent, test_entities)
        assert_equal(test_text, interpret.text)
        assert_equal(test_intent, interpret.intent)
        assert_equal(test_entities, interpret.entities)
    end

end
