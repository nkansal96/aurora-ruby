require 'test/unit'
require 'aurora-sdk'
require_relative '../test_helpers'

class TextTest < Test::Unit::TestCase
    include TestHelpers

    def test_create_text
        text = 'Aaaaaughibbrgubugbugrguburgle'

        # no text argument
        assert_raise(ArgumentError) {textObject = Aurora::Text.new}

        # normal functionality
        assert_equal(text, Aurora::Text.new(text).text)
    end

    def test_to_speech
        # text generated from random text generator
        test_text = 'camera trunk'

        speech = Aurora::Text.new(test_text).to_speech
        expected_speech = Aurora::Api.get_tts(test_text)
        assert_equal(expected_speech.audio.to_wav, speech.audio.to_wav)
    end

    def test_to_interpret
        text = 'what is the weather in Los Angeles'

        interpret = Aurora::Text.new(text).to_interpret
        expected_interpret = Aurora::Api.get_interpret(text)

        assert_equal(expected_interpret.text, interpret.text)
        assert_equal(expected_interpret.intent, interpret.intent)
        assert_equal(expected_interpret.entities['location'], interpret.entities['location'])
    end
end

# tests to see we have proper behavior when there are no credentials
class TextTestNoCreds < Test::Unit::TestCase
    def test_to_speech 
        # text generated from random text generator
        test_text = 'camera trunk'

        assert_raise(Aurora::Error::InvalidConfigError.new) {speech = Aurora::Text.new(test_text).to_speech}
    end

    def test_to_interpret
        text = 'what is the weather in Los Angeles'

        assert_raise(Aurora::Error::InvalidConfigError.new) {interpret = Aurora::Text.new(text).to_interpret}
    end
end