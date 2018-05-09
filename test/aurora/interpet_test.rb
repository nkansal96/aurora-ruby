require 'test/unit'
require 'aurora-sdk'
require_relative '../test_helpers'

class InterpretTest < Test::Unit::TestCase
    include TestHelpers

    def test_get_intepret
        text = 'what is the weather in los angeles?'
        interpret = Aurora::Api.get_interpret(text)

        assert_equal('what is the weather in los angeles', interpret.text)
        assert_equal('weather', interpret.intent)
        assert_equal('los angeles', interpret.entities['location'])
    end
end
