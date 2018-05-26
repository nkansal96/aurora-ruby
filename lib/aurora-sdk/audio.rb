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
            Audio.write_to_file(@audio, filename)
        end

        def play
            @playing = true
            Audio.play_wav(@audio)
            @playing = false
        end

        # TODO: Pads both sides of audio with specified amount of silence (in seconds)
        def pad(seconds)
        end

        # TODO: Pads the left side of the audio with the specified amount of silence (in seconds)
        def pad_left(seconds)
        end

        # TODO: Pads the right side of the audio with the specified amount of silence (in seconds)
        def pad_right
        end

        # TODO: Trims extraneous silence at the ends of the audio
        def trim_silence
        end

    end

    class Audio
        PA = Portaudio

        # Representation of WAV File
        WavFile = Struct.new(:chunk_id, :chunk_size, :format, :subchunk1_id, :subchunk1_size, :audio_format, :num_channels, :sample_rate, :byte_rate, :block_align, :bits_per_sample, :subchunk2_id, :subchunk2_size, :data)

        # Representation of field characteristics
        # :offset   = byte offset in file
        # :size     = size in bytes
        # :type     = format for unpacking (based on type and endian)
        #             'M' => string, 'I' => int, 'S' => short
        FieldInfo = Struct.new(:offset, :size, :type)

        # WAVE PCM Format based on http://soundfile.sapp.org/doc/WaveFormat/
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
        FRAMES_PER_BUFFER   = 1
        NUM_CHANNELS        = 1 # mono
        SAMPLE_TYPE         = PA::PaInt16
        SAMPLE_SIZE         = 2 # bytes per sample

        # Converts raw audio data into WAV formatted file
        def self.create_wav(data)
            wav = ""
            wav << 'RIFF'
            wav << [36 + data.size].pack(FIELD_INFO[:chunk_size].type)
            wav << 'WAVE'
            wav << 'fmt '
            wav << [16].pack(FIELD_INFO[:subchunk1_size].type)
            wav << [1].pack(FIELD_INFO[:audio_format].type)
            wav << [NUM_CHANNELS].pack(FIELD_INFO[:num_channels].type)
            wav << [SAMPLE_RATE].pack(FIELD_INFO[:sample_rate].type)
            wav << [SAMPLE_RATE * NUM_CHANNELS * SAMPLE_SIZE].pack(FIELD_INFO[:byte_rate].type)
            wav << [NUM_CHANNELS * SAMPLE_SIZE].pack(FIELD_INFO[:block_align].type)
            wav << [SAMPLE_SIZE * 8].pack(FIELD_INFO[:bits_per_sample].type)
            wav << 'data'
            wav << [data.size].pack(FIELD_INFO[:subchunk2_size].type)
            wav << data

            return wav
        end

        # Write WAV file to disk
        def self.write_to_file(wav, filename)
            File.open(filename, 'wb') do |file|
                file.write(wav)
            end
        end

        # Records for specified number of seconds and returns WAV formatted audio
        def self.record(seconds)
            stream = Fiddle::Pointer.new 0
            num_bytes = FRAMES_PER_BUFFER * NUM_CHANNELS * SAMPLE_SIZE
            sample_block = '0' * num_bytes  # Buffer string of size num_bytes
            data = String.new

            handle_error(PA.Pa_Initialize)
            handle_error(PA.Pa_OpenStream(stream.ref, get_input_params, nil, SAMPLE_RATE, FRAMES_PER_BUFFER, PA::PaClipOff, nil, nil))
            handle_error(PA.Pa_StartStream(stream))

            # Record audio
            num_samples = (seconds * SAMPLE_RATE) / FRAMES_PER_BUFFER
            (0..num_samples-1).each do |i|
                handle_error(PA.Pa_ReadStream(stream, sample_block, FRAMES_PER_BUFFER))
                data << sample_block
            end

            terminate(stream)
            create_wav(data)
        end

        def self.play_wav(data)
            play_audio(parse_wav_data(data))
        end

        def self.play_file(filename)
            play_audio(parse_wav_file(filename))
        end

        # Plays audio given WAV file data
        private_class_method def self.play_audio(wav)
            if !valid_wav?(wav)
                raise WAVFileError
            end

            stream = Fiddle::Pointer.new 0

            handle_error(PA.Pa_Initialize)
            handle_error(PA.Pa_OpenStream(stream.ref, nil, get_output_params(wav), wav.sample_rate, FRAMES_PER_BUFFER, PA::PaClipOff, nil, nil))
            handle_error(PA.Pa_StartStream(stream))

            # Play audio data by iterating through chunks
            wav.data.each do |buffer|
                handle_error(PA.Pa_WriteStream(stream, buffer, FRAMES_PER_BUFFER))
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

        private_class_method def self.get_output_params(wav)
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

            output_param.channelCount = wav.num_channels
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

        private_class_method def self.parse_wav_data(data)
            file_info = []
            sample_data = []

            FIELD_INFO.each do |info|
                buffer = data[(info[1].offset)..(info[1].offset + info[1].size - 1)]
                file_info << buffer.unpack(info[1].type).first
            end

            sample_size = file_info[10] / 8 # convert bits to bytes

            # Add remainder of wav as sample data
            (DATA_OFFSET..(data.size-1)).step(sample_size).each do |i|
                sample_data << data[i..(i+sample_size - 1)]
            end

            file_info << sample_data
            WavFile.new(*file_info)
        end

        private_class_method def self.parse_wav_file(filename)
            file_info = []
            sample_data = []

            File.open(filename) do |file|
                FIELD_INFO.each do |info|
                    buffer = file.read(info[1].size)
                    file_info << buffer.unpack(info[1].type).first
                end

                sample_size = file_info[10] / 8 # convert bits to bytes

                # Add remainder of file as data
                while (buffer = file.read(sample_size)) do
                    sample_data << buffer
                end
            end

            file_info << sample_data
            WavFile.new(*file_info)
        end

        # TODO: Validates file headers with expected values for WAV format
        private_class_method def self.valid_wav?(wav)
            return true
        end
    end
end
