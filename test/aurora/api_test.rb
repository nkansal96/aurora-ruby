require 'test/unit'
require 'aurora-sdk'
require_relative '../test_helpers'

class ApiTest < Test::Unit::TestCase
    include TestHelpers

    # get_stt tests
    def test_get_stt
        speech_file = File.open("test/testfiles/test_audio_base.wav", "rb")

        test_stt = Aurora::Api.get_stt(Aurora::AudioFile.new(speech_file.read))
        assert_equal('Check 123', test_stt.text)
    end

    # get_tts tests
    def test_get_tts
        test_text = "Check one two three"
        speech_file = File.open("test/testfiles/test_audio_base.wav", "rb")
        expected_speech = Aurora::AudioFile.new(speech_file.read)

        test_tts = Aurora::Api.get_tts(test_text)
        assert_equal(expected_speech.to_wav, test_tts.audio.to_wav)
    end

    # get_interpret tests
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
        assert_equal('world', interpret.entities['song'])

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
