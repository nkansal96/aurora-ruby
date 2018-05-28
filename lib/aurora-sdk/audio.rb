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
        def pad_right(seconds)
        end

        # TODO: Trims extraneous silence at the ends of the audio
        def trim_silence
            @audio = Audio.trim_silence(@audio)
        end

    end

    class Audio
        PA = Portaudio

        # Representation of WAV File
        WavFile = Struct.new(:chunk_id, :chunk_size, :fformat, :subchunk1_id, :subchunk1_size, :audio_format, :num_channels, :sample_rate, :byte_rate, :block_align, :bits_per_sample, :subchunk2_id, :subchunk2_size, :data)

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
            :fformat => FieldInfo.new(8, 4, 'M'),
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

        # Adds WAV headers to raw audio data and returns WAV formatted byte string
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

        # Write WAV data to disk
        def self.write_to_file(wav, filename)
            File.open(filename, 'wb') do |file|
                file.write(wav)
            end
        end

        # TODO: Trims extraneous silence at the ends of audio data
        def self.trim_silence(data)
            # wav = parse_wav_data(data)
            # puts wav.data.size
            # # Trim silence from front
            # while wav.data.shift == "\x00\x00"
            # end
            # puts wav.data.size
            # sample_size = wav.bits_per_sample / 8
            # dir = "a#{sample_size}" * (wav.subchunk2_size/sample_size)
            # data[0..DATA_OFFSET-1] + (wav.data).pack(dir)
        end

        # Records for specified number of seconds and returns AudioFile
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
            AudioFile.new(create_wav(data))
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
            handle_error(PA.Pa_AbortStream(stream))
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
            if ![PA::PaErrorCode::PaNoError, PA::PaErrorCode::PaInputOverflowed].include? err
                PA.Pa_Terminate
                raise PortAudioError.new(PA.Pa_GetErrorText(err))
            end
        end

        private_class_method def self.parse_wav_data(data)
            file_info = []

            FIELD_INFO.each do |info|
                buffer = data[(info[1].offset)..(info[1].offset + info[1].size - 1)]
                file_info << buffer.unpack(info[1].type).first
            end

            sample_size = file_info[10] / 8 # convert bits to bytes

            # Unpacks sample string into array of size = subchunk2_size
            sample_data = data[DATA_OFFSET..(data.size-1)].unpack "a#{sample_size}" * (file_info[12]/sample_size)
            file_info << sample_data

            WavFile.new(*file_info)
        end

        private_class_method def self.parse_wav_file(filename)
            parse_wav_data(File.read(filename))
        end

        # Validates headers of WavFile struct with WAV format used for Aurora
        private_class_method def self.valid_wav?(wav)
            if (wav.chunk_id != 'RIFF' ||
                wav.chunk_size != (4 + (8 + wav.subchunk1_size) + (8 + wav.subchunk2_size)) ||
                wav.fformat != 'WAVE' ||
                wav.subchunk1_id != 'fmt ' ||
                wav.subchunk1_size != 16 ||
                wav.audio_format != 1 ||
                wav.num_channels != NUM_CHANNELS ||
                wav.sample_rate != SAMPLE_RATE ||
                wav.byte_rate != wav.sample_rate * wav.num_channels * (wav.bits_per_sample/8) ||
                wav.block_align != wav.num_channels * (wav.bits_per_sample/8) ||
                wav.subchunk2_id != 'data' ||
                wav.subchunk2_size != wav.data.size*(wav.bits_per_sample/8))
            then
                return false
            end
            return true
        end
    end
end
