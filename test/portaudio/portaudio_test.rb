require 'test/unit'
require_relative '../../lib/portaudio'

# Smoke tests -- make sure dylib loads correctly, etc

class PortaudioTest < Test::Unit::TestCase
    def test_lib_loaded
        version = Portaudio.Pa_GetVersion
        assert(version > 0)
    end

    def test_init
        err = Portaudio.Pa_Initialize
        assert_equal(err, Portaudio::PaErrorCode::PaNoError)
    end

    def test_terminate
        Portaudio.Pa_Initialize
        err = Portaudio.Pa_Terminate
        assert_equal(err, Portaudio::PaErrorCode::PaNoError)
    end
end
