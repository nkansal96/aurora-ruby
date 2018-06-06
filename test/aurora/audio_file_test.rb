require 'test/unit'
require 'aurora-sdk'
require_relative '../test_helpers'

class AudioFileTest < Test::Unit::TestCase
    include TestHelpers

    # tests creation of AudioFile object with no argument
    def test_create_no_arg
        assert_raise(ArgumentError) {audio_file = Aurora::AudioFile.new}
    end

    # test creation of AudioFile object based on wav file
    def test_create_normal
        file = File.open("test/testfiles/test_normal_speech1.wav", "rb")

        audio_object = Aurora::AudioFile.new(file.read)

        assert_equal(false, audio_object.playing)
        assert_equal(false ,audio_object.should_stop)
    end

    def test_to_wav
        file = File.open("test/testfiles/test_normal_speech1.wav", "rb")
        content = file.read

        audio_object = Aurora::AudioFile.new(content)

        assert_equal(content, audio_object.to_wav)
    end

    # writes to a tempfile and checks if content is the same
    def test_write_to_file
        file = File.open("test/testfiles/test_normal_speech1.wav", "rb")
        content = file.read

        audio_object = Aurora::AudioFile.new(content)
        audio_object.write_to_file("/tmp/test.wav")

        created_file = File.open("/tmp/test.wav", "rb")
        assert_equal(content, created_file.read)
    end

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
    def test_base_trim
        exp_file = File.open("test/testfiles/test_audio_trimmed.wav", "rb")
        expected_audio = Aurora::AudioFile.new(exp_file.read)
        test_file = File.open("test/testfiles/test_audio_base.wav", "rb")
        test_audio_bang = Aurora::AudioFile.new(test_file.read)
        test_audio = test_audio_bang.trim_silence
        test_audio_bang.trim_silence!
        
        assert_equal(expected_audio.to_wav, test_audio.to_wav)
        assert_equal(expected_audio.to_wav, test_audio_bang.to_wav)
    end

    def test_double_trim
        exp_file = File.open("test/testfiles/test_audio_trimmed_dp.wav", "rb")
        expected_audio = Aurora::AudioFile.new(exp_file.read)
        test_file = File.open("test/testfiles/test_audio_double_pad.wav", "rb")
        test_audio_bang = Aurora::AudioFile.new(test_file.read)
        test_audio = test_audio_bang.trim_silence
        test_audio_bang.trim_silence!
        
        assert_equal(expected_audio.to_wav, test_audio.to_wav)
        assert_equal(expected_audio.to_wav, test_audio_bang.to_wav)
    end

    def test_left_trim
        exp_file = File.open("test/testfiles/test_audio_trimmed_lp.wav", "rb")
        expected_audio = Aurora::AudioFile.new(exp_file.read)
        test_file = File.open("test/testfiles/test_audio_left_pad.wav", "rb")
        test_audio_bang = Aurora::AudioFile.new(test_file.read)
        test_audio = test_audio_bang.trim_silence
        test_audio_bang.trim_silence!
        
        assert_equal(expected_audio.to_wav, test_audio.to_wav)
        assert_equal(expected_audio.to_wav, test_audio_bang.to_wav)
    end
  
    def test_right_trim
        exp_file = File.open("test/testfiles/test_audio_trimmed_rp.wav", "rb")
        expected_audio = Aurora::AudioFile.new(exp_file.read)
        test_file = File.open("test/testfiles/test_audio_right_pad.wav", "rb")
        test_audio_bang = Aurora::AudioFile.new(test_file.read)
        test_audio = test_audio_bang.trim_silence
        test_audio_bang.trim_silence!
        
        assert_equal(expected_audio.to_wav, test_audio.to_wav)
        assert_equal(expected_audio.to_wav, test_audio_bang.to_wav)
    end
end
