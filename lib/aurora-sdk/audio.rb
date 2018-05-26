require 'enumerator'
require_relative '../portaudio'

module Aurora
    class AudioFile
        attr_reader :playing, :should_stop

        def initialize(audio, playing = false, should_stop = false)
            @audio = audio
            @playing = playing
            @should_stop = should_stop
        end

        def to_wav
            @audio
        end

        def write_to_file(filename)
            open(filename, 'wb') do |file|
                file.write(@audio)
            end
        end

        def play
            @playing = true
            Audio.play_wav(@audio)
            @playing = false
        end
    end

    class Audio
        PA = Portaudio

        # WAVE PCM Format based on http://soundfile.sapp.org/doc/WaveFormat/
        # Representation of WAV File contents
        # TODO: remove
        WavFile = Struct.new(:chunk_id, :chunk_size, :format, :subchunk1_id, :subchunk1_size, :audio_format, :num_channels, :sample_rate, :byte_rate, :block_align, :bits_per_sample, :subchunk2_id, :subchunk2_size, :data)

        # Representation of field characteristics
        # :offset   = byte offset in file
        # :size     = size in bytes
        # :type     = format for unpacking (based on type and endian)
        #             'M' => string, 'I' => int, 'S' => short
        FieldInfo = Struct.new(:offset, :size, :type)

        FIELD_INFO = {
            :chunk_id => FieldInfo.new(0, 4, 'M'),
            :chunk_size => FieldInfo.new(4, 4, 'I'),
            :format => FieldInfo.new(8, 4, 'M'),
            :subchunk1_id => FieldInfo.new(12, 4, 'M'),
            :subchunk1_size => FieldInfo.new(16, 4, 'I'),
            :audio_format => FieldInfo.new(20, 2, 'S'),
            :num_channels => FieldInfo.new(22, 2, 'S'),
            :sample_rate => FieldInfo.new(24, 4, 'I'),
            :byte_rate => FieldInfo.new(28, 4, 'I'),
            :block_align => FieldInfo.new(32, 2, 'S'),
            :bits_per_sample => FieldInfo.new(34, 2, 'S'),
            :subchunk2_id => FieldInfo.new(36, 4, 'M'),
            :subchunk2_size => FieldInfo.new(40, 4, 'I')
        }

        DATA_OFFSET         = 44

        SAMPLE_RATE         = 16000
        FRAMES_PER_BUFFER   = 2
        NUM_CHANNELS        = 1 # mono
        SAMPLE_TYPE         = PA::PaInt16
        SAMPLE_SIZE         = 4

        def self.record(seconds)
            stream = Fiddle::Pointer.new 0
            num_bytes = FRAMES_PER_BUFFER * NUM_CHANNELS * SAMPLE_SIZE
            sample_block = '0000'
            data = String.new

            handle_error(PA.Pa_Initialize)
            handle_error(PA.Pa_OpenStream(stream.ref, get_input_params, nil, SAMPLE_RATE, FRAMES_PER_BUFFER, PA::PaClipOff, nil, nil))
            handle_error(PA.Pa_StartStream(stream))

            # Record audio
            record_max = ((seconds * SAMPLE_RATE)/ FRAMES_PER_BUFFER) - 1
            (0..record_max).each do |i|
                handle_error(PA.Pa_ReadStream(stream, sample_block, FRAMES_PER_BUFFER))
                puts sample_block
                data << sample_block
            end

            terminate(stream)

            play_wav(data)
            create_wav_file(data, 'record.wav')
        end

        def self.parse_wav_file(filename)
            file_info = []
            File.open(filename) do |file|
                FIELD_INFO.each do |info|
                    buffer = file.read(info[1].size)
                    file_info << buffer.unpack(info[1].type)
                end

                # Add remainder of file as data
                file_info << file.read
            end
            WavFile.new(file_info)
        end

        def self.create_wav_file(data, filename)
            headers = nil
            File.open('headers') do |file|
                headers = file.read(DATA_OFFSET)
            end

            File.open(filename, 'wb') do |file|
                file.write('RIFF')
                file.write(data)
            end
        end

        def self.play_wav(data)
            if !valid_wav?(data)
                raise WAVFileError
            end

            stream = Fiddle::Pointer.new 0

            handle_error(PA.Pa_Initialize)
            handle_error(PA.Pa_OpenStream(stream.ref, nil, get_output_params, SAMPLE_RATE, FRAMES_PER_BUFFER, PA::PaClipOff, nil, nil))
            handle_error(PA.Pa_StartStream(stream))


            # Play audio data by iterating through chunks
            (DATA_OFFSET..data.length-1).step(SAMPLE_SIZE).each do |i|
                buffer = data[i..(i+SAMPLE_SIZE-1)]
                handle_error(PA.Pa_WriteStream(stream, buffer, FRAMES_PER_BUFFER))
            end

            terminate(stream)
        end

        def self.play_file(filename)
            stream = Fiddle::Pointer.new 0

            handle_error(PA.Pa_Initialize)
            handle_error(PA.Pa_OpenStream(stream.ref, nil, get_output_params, SAMPLE_RATE, FRAMES_PER_BUFFER, PA::PaClipOff, nil, nil))
            handle_error(PA.Pa_StartStream(stream))

            # Read audio file in chunks and play
            File.open(filename) do |file|
                if !valid_wav?(file)
                    raise WAVFileError
                end

                # Play back audio by writing to stream
                file.seek DATA_OFFSET
                while (buffer = file.read(SAMPLE_SIZE)) do
                    handle_error(PA.Pa_WriteStream(stream, buffer, FRAMES_PER_BUFFER))
                end
            end

            terminate(stream)
        end

        private_class_method def self.terminate(stream)
            handle_error(PA.Pa_StopStream(stream))
            handle_error(PA.Pa_CloseStream(stream))
            handle_error(PA.Pa_Terminate)
        end

        private_class_method def self.get_input_params
            input_param = PA::PaStreamParameters.malloc

            # Initialize output parameters
            input_param.device = PA.Pa_GetDefaultInputDevice
            if input_param.device < 0
                PA.Pa_Terminate
                raise PortAudioError.new('Input device not found.')
            end

            input_info = PA::Pa_GetDeviceInfo(input_param.device)
            if input_info.null?
                PA.Pa_Terminate
                raise PortAudioError.new('Error getting device info')
            end
            input_info = PA::PaDeviceInfo.new(input_info)

            input_param.channelCount = NUM_CHANNELS
            input_param.sampleFormat = SAMPLE_TYPE
            input_param.suggestedLatency = input_info.defaultHighInputLatency
            input_param.hostApiSpecificStreamInfo = nil

            return input_param
        end

        private_class_method def self.get_output_params
            output_param = PA::PaStreamParameters.malloc

            # Initialize output parameters
            output_param.device = PA.Pa_GetDefaultOutputDevice
            if output_param.device < 0
                PA.Pa_Terminate
                raise PortAudioError.new('Output device not found.')
            end

            output_info = PA::Pa_GetDeviceInfo(output_param.device)
            if output_info.null?
                PA.Pa_Terminate
                raise PortAudioError.new('Error getting device info')
            end
            output_info = PA::PaDeviceInfo.new(output_info)

            output_param.channelCount = NUM_CHANNELS
            output_param.sampleFormat = SAMPLE_TYPE
            output_param.suggestedLatency = output_info.defaultHighOutputLatency
            output_param.hostApiSpecificStreamInfo = nil

            return output_param
        end

        private_class_method def self.handle_error(err)
            if err != PA::PaErrorCode::PaNoError
                PA.Pa_Terminate
                raise PortAudioError.new(PA.Pa_GetErrorText(err))
            end
        end

        # TODO: Validates file headers with expected values for WAV format
        private_class_method def self.valid_wav?(file)

        end
    end
end
