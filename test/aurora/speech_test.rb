require 'test/unit'
require 'aurora-sdk'
require_relative '../test_helpers'

class SpeechTest < Test::Unit::TestCase
    include TestHelpers

    # tests creation of a speech object with no argument
    def test_create_no_arg
        assert_raise(ArgumentError) {speech = Aurora::Speech.new}
    end

    # tests the creation of a speech object based on invalid input as an argument
    def test_create_bad_arg
        arg = 42

        # wrong argument type error
        assert_raise(Aurora::Error::AudioTypeError.new(arg.class)) {audio_file = Aurora::Speech.new(arg)}
    end

    # test creation of a speech object based on normal audio object file
    def test_create_normal
        file = File.open("test/testfiles/test_normal_speech1.wav", "rb")

        audio_object = Aurora::AudioFile.new(file.read)

        assert_equal(audio_object, Aurora::Speech.new(audio_object).audio)
    end
    
    # tests to_text on a wav file generated by aurora
    def test_to_text_normal1
        file = File.open("test/testfiles/test_normal_speech1.wav", "rb")

        audio_object = Aurora::AudioFile.new(file.read)
        text_object = Aurora::Speech.new(audio_object).to_text

        assert_equal("hello world", text_object.text.downcase)
    end

    def test_to_text_normal2
        file = File.open("test/testfiles/test_normal_speech2.wav", "rb")

        audio_object = Aurora::AudioFile.new(file.read)
        text_object = Aurora::Speech.new(audio_object).to_text

        assert_equal("remind me to do laundry tomorrow", text_object.text.downcase)
    end

    # tests to_text on a wav file generated by human speech
    def test_to_text_human_speech
        file = File.open("test/testfiles/test_human_speech.wav", "rb")

        audio_object = Aurora::AudioFile.new(file.read)
        text_object = Aurora::Speech.new(audio_object).to_text

        assert_equal("remind me to do laundry tomorrow", text_object.text.downcase)
    end
end

# tests to see we have proper behavior when there are no credentials
class SpeechTestNoCreds < Test::Unit::TestCase
    def test_to_text 
        file = File.open("test/testfiles/test_normal_speech1.wav", "rb")

        audio_object = Aurora::AudioFile.new(file.read)

        assert_raise(Aurora::Error::InvalidConfigError.new) {text_object = Aurora::Speech.new(audio_object).to_text}
    end
end