require 'test/unit'
require 'aurora-sdk'
require_relative '../test_helpers'

class AudioFileTest < Test::Unit::TestCase
    include TestHelpers

    # test padding functions
    def test_pad
        exp_file = File.open("test/testfiles/test_audio_double_pad.wav", "rb")
        expected_audio = Aurora::AudioFile.new(exp_file.read)
        test_file = File.open("test/testfiles/test_audio_base.wav", "rb")
        test_audio = Aurora::AudioFile.new(test_file.read)
        test_audio_bang = test_audio.pad(1)
        test_audio.pad!(1)
        
        assert_equal(expected_audio.to_wav, test_audio.to_wav)
        assert_equal(expected_audio.to_wav, test_audio_bang.to_wav)
    end

    def test_left_pad
        exp_file = File.open("test/testfiles/test_audio_left_pad.wav", "rb")
        expected_audio = Aurora::AudioFile.new(exp_file.read)
        test_file = File.open("test/testfiles/test_audio_base.wav", "rb")
        test_audio = Aurora::AudioFile.new(test_file.read)
        test_audio_bang = test_audio.pad_left(1)
        test_audio.pad_left!(1)
        
        assert_equal(expected_audio.to_wav, test_audio.to_wav)
        assert_equal(expected_audio.to_wav, test_audio_bang.to_wav)
    end

    def test_right_pad
        exp_file = File.open("test/testfiles/test_audio_right_pad.wav", "rb")
        expected_audio = Aurora::AudioFile.new(exp_file.read)
        test_file = File.open("test/testfiles/test_audio_base.wav", "rb")
        test_audio = Aurora::AudioFile.new(test_file.read)
        test_audio_bang = test_audio.pad_right(1)
        test_audio.pad_right!(1)
        
        assert_equal(expected_audio.to_wav, test_audio.to_wav)
        assert_equal(expected_audio.to_wav, test_audio_bang.to_wav)
    end

    # test trimming functions
    def test_double_trim
        exp_file = File.open("test/testfiles/test_audio_trimmed.wav", "rb")
        expected_audio = Aurora::AudioFile.new(exp_file.read)
        test_file = File.open("test/testfiles/test_audio_double_pad.wav", "rb")
        test_audio_bang = Aurora::AudioFile.new(test_file.read)
        test_audio = test_audio_bang.trim_silence
        test_audio_bang.trim_silence!
        
        assert_equal(expected_audio.to_wav, test_audio.to_wav)
        assert_equal(expected_audio.to_wav, test_audio_bang.to_wav)
    end

    def test_left_trim
        exp_file = File.open("test/testfiles/test_audio_trimmed.wav", "rb")
        expected_audio = Aurora::AudioFile.new(exp_file.read)
        test_file = File.open("test/testfiles/test_audio_left_pad.wav", "rb")
        test_audio_bang = Aurora::AudioFile.new(test_file.read)
        test_audio = test_audio_bang.trim_silence
        test_audio_bang.trim_silence!
        
        assert_equal(expected_audio.to_wav, test_audio.to_wav)
        assert_equal(expected_audio.to_wav, test_audio_bang.to_wav)
    end
  
    def test_right_trim
        exp_file = File.open("test/testfiles/test_audio_trimmed.wav", "rb")
        expected_audio = Aurora::AudioFile.new(exp_file.read)
        test_file = File.open("test/testfiles/test_audio_right_pad.wav", "rb")
        test_audio_bang = Aurora::AudioFile.new(test_file.read)
        test_audio = test_audio_bang.trim_silence
        test_audio_bang.trim_silence!
        
        assert_equal(expected_audio.to_wav, test_audio.to_wav)
        assert_equal(expected_audio.to_wav, test_audio_bang.to_wav)
    end
end
