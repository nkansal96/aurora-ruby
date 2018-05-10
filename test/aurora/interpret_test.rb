require 'test/unit'
require 'aurora-sdk'
require_relative '../test_helpers'

class InterpretTest < Test::Unit::TestCase
    include TestHelpers

    def test_interpret_weather
        text = 'what is the weather in los angeles?'
        interpret = Aurora::Api.get_interpret(text)

        assert_equal('what is the weather in los angeles', interpret.text)
        assert_equal('weather', interpret.intent)
        assert_equal('los angeles', interpret.entities['location'])
    end

    def test_interpret_greeting
        text = 'hello world'
        interpret = Aurora::Api.get_interpret(text)

        assert_equal(text, interpret.text)
        assert_equal('greeting', interpret.intent)
        assert_equal({}, interpret.entities)
    end

    def test_interpret_time
        text = 'what time is it in copenhagen'
        interpret = Aurora::Api.get_interpret(text)

        assert_equal(text, interpret.text)
        assert_equal('time', interpret.intent)
        assert_equal('copenhagen', interpret.entities['location'])
    end

    def test_nonsense
        text = 'weoiafjfioewafj'
        interpret = Aurora::Api.get_interpret(text)

        assert_equal(text, interpret.text)
        assert_equal('', interpret.intent)
        assert_equal({}, interpret.entities)
    end
end
