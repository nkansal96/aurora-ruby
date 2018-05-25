require_relative '../portaudio'

module Aurora
    class Audio
        PA = Portaudio

        # WAVE PCM Format based on http://soundfile.sapp.org/doc/WaveFormat/
        SAMPLE_RATE = 16000
        FRAMES_PER_BUFFER = 2
        NUM_CHANNELS = 1 # mono
        SAMPLE_TYPE = PA::PaInt16

        # WAVE File Data Offsets (in bytes)
        CHUNK_SIZE              = 4
        CHUNK_SIZE_OFFSET       = 4
        NUM_CHANNELS_OFFSET     = 22
        DATA_OFFSET             = 44

        def self.play_wav(filename)
            # Initialize PortAudio
            err = PA.Pa_Initialize
            handle_error(err)

            stream = Fiddle::Pointer.malloc 0
            output_param = PA::PaStreamParameters.malloc

            # Initialize output parameters
            output_param.device = PA.Pa_GetDefaultOutputDevice
            if output_param.device < 0
                puts 'Output device not found.'
                exit
            end

            output_param.channelCount = NUM_CHANNELS
            output_param.sampleFormat = SAMPLE_TYPE
            output_device_info = PA::Pa_GetDeviceInfo(output_param.device)
            if output_device_info.null?
                puts 'Error getting device info'
                exit
            end

            output_device_info = PA::PaDeviceInfo.new(output_device_info)
            output_param.suggestedLatency = output_device_info.defaultLowOutputLatency
            output_param.hostApiSpecificStreamInfo = nil

            # Open stream
            err = PA.Pa_OpenStream(stream.ref, nil, output_param, SAMPLE_RATE, FRAMES_PER_BUFFER, PA::PaClipOff, nil, nil)
            handle_error(err)

            # Start stream
            err = PA.Pa_StartStream(stream)
            handle_error(err)

            # Read audio file in chunks and play
            File.open(filename) do |file|
                if !valid_wav?(file)
                    raise WAVFileError
                end

                # Play back audio by writing to stream
                file.seek DATA_OFFSET
                while (buffer = file.read(CHUNK_SIZE)) do
                    err = PA.Pa_WriteStream(stream, buffer, FRAMES_PER_BUFFER)
                    handle_error(err)
                end
            end

            err = PA.Pa_StopStream(stream)
            handle_error(err)

            err = PA.Pa_CloseStream(stream)
            handle_error(err)

            err = PA.Pa_Terminate
            handle_error(err)
        end

        private_class_method def self.handle_error(err)
            if err != PA::PaErrorCode::PaNoError
                puts PA.Pa_GetErrorText(err)
                PA.Pa_Terminate
                exit
            end
        end

        # TODO: Validates file headers with expected values for WAV format
        private_class_method def self.valid_wav?(file)
            # file.seek CHUNK_SIZE_OFFSET
            # chunk_size = file.read(CHUNK_SIZE).unpack('V')
            # puts chunk_size
            # if chunk_size != CHUNK_SIZE
            #     return false
            # end
            #
            # file.seek NUM_CHANNELS_OFFSET
            # num_channels = file.read(2).unpack("I<*")
            # puts num_channels
            # if num_channels != NUM_CHANNELS
            #    return false
            # end
            return true
        end
    end
end
