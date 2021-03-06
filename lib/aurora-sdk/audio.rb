require_relative '../portaudio'
require_relative 'audio_file'

module Aurora
    # Implementation of how the SDK handles audio
    class Audio
        PA = Portaudio

        # Representation of WAV File Format based on http://soundfile.sapp.org/doc/WaveFormat/
        WavFile = Struct.new(:chunk_id, :chunk_size, :fformat, :subchunk1_id, :subchunk1_size, :audio_format, :num_channels, :sample_rate, :byte_rate, :block_align, :bits_per_sample, :subchunk2_id, :subchunk2_size, :data)

        # Representation of field characteristics
        #
        # @attr offset [Int] Byte offset of field in file
        # @attr size [Int] Field size in bytes
        # @attr type [String] Format for unpacking based on type and endian
        FieldInfo = Struct.new(:offset, :size, :type)

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

        SILENCE_THRESHOLD   = 2048
        SAMPLE_RATE         = 16000
        FRAMES_PER_BUFFER   = 1
        NUM_CHANNELS        = 1 # mono
        SAMPLE_TYPE         = PA::PaInt16
        SAMPLE_SIZE         = 2 # bytes per sample
        BYTES_PER_BLOCK     = FRAMES_PER_BUFFER * NUM_CHANNELS * SAMPLE_SIZE

        # Adds WAV headers to raw audio data and returns WAV formatted byte string
        #
        # @param data [String] Raw audio data binary string
        # @param spec_size [Int] Option to manually specify size of file.
        #                        If 0, data.size is automatically used
        #
        # @return [String] Binary string representation of WAV File
        def self.create_wav(data, spec_size=0)
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
            wav << [(spec_size == 0 ? data.size : spec_size)].pack(FIELD_INFO[:subchunk2_size].type)
            wav << data

            return wav
        end

        # Write WAV data to disk
        #
        # @param wav [String] Binary string representation of WAV file
        # @param filename [String] File path to write to
        #
        # @return [Int] Number of bytes written in total
        def self.write_to_file(wav, filename)
            File.open(filename, 'wb') do |file|
                file.write(wav)
            end
        end

        # Trims extraneous silence at the ends of audio data
        #
        # @param threshold [Float] Decimal between 0 and 1 relative to max amplitude
        # @param padding [Float] Time in seconds to re-add from original audio data to trimmed clip
        #
        # @return [String] Binary string representation of WAV file
        def self.trim_silence(threshold, padding, data)
            wav = parse_wav_data(data)
            values = get_sample_values(wav.data)
            max_amplitude = (1 << wav.bits_per_sample) / 2.0
            silence_threshold = threshold * max_amplitude

            # Trim silence from front
            front = 0
            while (rms [values[front]]) <= silence_threshold && front < values.size - 1
                front += 1
            end

            # Trim silence from back
            back = values.size - 1
            while (rms [values[back]]) <= silence_threshold && back >= 0
                back -= 1
            end

            # Add padding
            sample_size = wav.bits_per_sample / 8
            pad = padding * wav.sample_rate * sample_size
            front_pad = [front-pad, 0].max
            back_pad = [back+pad, values.size-1].min
            create_wav((values[front_pad..back_pad]).pack('s*'))
        end

        # Pads the left side of the audio with the specified amount of silence (in seconds)
        #
        # @param data [String] Binary string representation of WAV file
        # @param seconds [Float] Seconds of silence to pad
        #
        # @return [String]
        def self.pad_left(data, seconds)
            pad(data, seconds, true, false)
        end

        # Pads the right side of the audio with the specified amount of silence (in seconds)
        #
        # @param data [String] Binary string representation of WAV file
        # @param seconds [Float] Seconds of silence to pad
        #
        # @return [String]
        def self.pad_right(data, seconds)
            pad(data, seconds, false, true)
        end

        # Pads sides of audio with specified amount of silence (in seconds)
        #
        # @param data [String] Binary string representation of WAV file
        # @param seconds [Float] Seconds of silence to pad
        # @param left [Bool] Enables padding to beginning of file
        # @param right [Bool] Enables padding to end of file
        #
        # @return [String]
        def self.pad(data, seconds, left = true, right = true)
            wav = parse_wav_data(data)
            sample_size = wav.bits_per_sample / 8
            pad_size = seconds * wav.sample_rate
            if left
                wav.data.unshift(*Array.new(pad_size, "\x00" * sample_size))
            end
            if right
                wav.data.push(*Array.new(pad_size, "\x00" * sample_size))
            end

            create_wav(wav.data.join)
        end

        # Records audio according to the given parameters and returns an instance of an AudioFile with the recorded audio
        #
        # @param seconds [Float] The time (in seconds) to listen for.
        #                       A value of 0 means that the recording framework will
        #                       continue to listen until the specified amount of
        #                       silence. A value greater than 0 will override any
        #                       value set to 'silence_len'.
        # @param silence_len [Float] How long silence (in seconds) will be
        #                            allowed before automatically stopping. This
        #                            value is only taken into consideration if
        #                            'length' is 0.
        #
        # @return [Aurora::AudioFile]
        def self.record(seconds, silence_len)
            if seconds <= 0 and silence_len <= 0
                raise ArgError.new("The arguments for seconds and silence_len must be at least 0")
                return nil
            end

            record_enum = get_record_enum(seconds, silence_len)

            data = String.new

            record_enum.each do |chunk|
                data << chunk
            end

            AudioFile.new(create_wav(data))
        end

        # Returns appropriate recording enumerator based on parameters given
        #
        # @param seconds [Float] The time (in seconds) to listen for.
        #                       A value of 0 means that the recording framework will
        #                       continue to listen until the specified amount of
        #                       silence. A value greater than 0 will override any
        #                       value set to 'silence_len'.
        # @param silence_len [Float] How long silence (in seconds) will be
        #                            allowed before automatically stopping. This
        #                            value is only taken into consideration if
        #                            'length' is 0.
        #
        # @return [Enumerator]
        def self.get_record_enum(seconds, silence_len)
            if seconds > 0
                return record_for_time(seconds)
            elsif silence_len > 0
                return record_until_silence(silence_len)
            end

            return nil
        end

        # Records for specified number of seconds and returns AudioFile
        #
        # @param seconds [Float] The time (in seconds) to listen for.
        #
        # @return [Enumerator]
        def self.record_for_time(seconds)
            Enumerator.new {|y|
                stream = Fiddle::Pointer.new 0
                sample_block = '0' * BYTES_PER_BLOCK  # Buffer string of size BYTES_PER_BLOCK

                init_input_stream(stream)

                num_samples = (seconds * SAMPLE_RATE) / FRAMES_PER_BUFFER

                y.yield wait_on_silence(stream)

                # Record audio
                (0..num_samples-1).each do |i|
                    handle_error(PA.Pa_ReadStream(stream, sample_block, FRAMES_PER_BUFFER), stream)
                    y.yield sample_block
                end

                terminate_stream(stream)
            }
        end

        # Records until silence of specified length is detected
        #
        # @param silence_len [Float] How long silence (in seconds) will be
        #
        # @return [Enumerator]
        def self.record_until_silence(silence_len)
            Enumerator.new {|y|
                stream = Fiddle::Pointer.new 0
                sample_block = '0' * BYTES_PER_BLOCK  # Buffer string of size BYTES_PER_BLOCK

                init_input_stream(stream)

                num_silence_samples = (silence_len * SAMPLE_RATE) / FRAMES_PER_BUFFER
                silence_counter = 0

                y.yield wait_on_silence(stream)

                # Record audio
                while true
                    handle_error(PA.Pa_ReadStream(stream, sample_block, FRAMES_PER_BUFFER), stream)
                    y.yield sample_block

                    if silent? [sample_block]
                        silence_counter += 1
                    else
                        silence_counter = 0
                    end

                    if silence_counter >= num_silence_samples
                        break
                    end
                end

                terminate_stream(stream)
            }
        end

        # Plays audio formatted as binary string representation of WAV file
        #
        # @param data [String] Binary string representation of WAV file
        def self.play_wav(data)
            play_audio(parse_wav_data(data))
        end

        # Plays audio file located at the specified path
        #
        # @param filename [String] Path of audio file
        def self.play_file(filename)
            play_audio(parse_wav_file(filename))
        end

        # Plays audio given WAV file data
        private_class_method def self.play_audio(wav)
            if !valid_wav?(wav)
                raise Error::WAVFileError
            end

            stream = Fiddle::Pointer.new 0

            handle_error(PA.Pa_Initialize, stream)
            handle_error(PA.Pa_OpenStream(stream.ref, nil, get_output_params(wav), wav.sample_rate, FRAMES_PER_BUFFER, PA::PaClipOff, nil, nil), stream)
            handle_error(PA.Pa_StartStream(stream), stream)

            # Play audio data by iterating through chunks
            wav.data.each do |buffer|
                handle_error(PA.Pa_WriteStream(stream, buffer, FRAMES_PER_BUFFER), stream)
            end

            terminate_stream(stream)
        end

        private_class_method def self.wait_on_silence(stream)
            sample_block = '0' * BYTES_PER_BLOCK  # Buffer string of size BYTES_PER_BLOCK
            padding_size = (0.1 * SAMPLE_RATE) / FRAMES_PER_BUFFER # 0.1 is an arbitrary padding number (in seconds)
            buffer = ''

            loop do
                handle_error(PA.Pa_ReadStream(stream, sample_block, FRAMES_PER_BUFFER), stream)
                buffer << sample_block
                if buffer.size > 8 * padding_size   # 8 is determined from trial-and-error
                    buffer = buffer[padding_size..buffer.size]
                end
                break if !silent? [sample_block]
            end

            buffer
        end

        private_class_method def self.init_input_stream(stream)
            handle_error(PA.Pa_Initialize, stream)
            handle_error(PA.Pa_OpenStream(stream.ref, get_input_params, nil, SAMPLE_RATE, FRAMES_PER_BUFFER, PA::PaClipOff, nil, nil), stream)
            handle_error(PA.Pa_StartStream(stream), stream)
        end

        private_class_method def self.terminate_stream(stream)
            handle_error(PA.Pa_StopStream(stream), stream)
            handle_error(PA.Pa_CloseStream(stream), stream)
            handle_error(PA.Pa_Terminate, stream)
        end

        private_class_method def self.get_input_params
            input_param = PA::PaStreamParameters.malloc

            # Initialize output parameters
            input_param.device = PA.Pa_GetDefaultInputDevice
            if input_param.device < 0
                PA.Pa_Terminate
                raise Error::PortAudioError.new('Input device not found.')
            end

            input_info = PA::Pa_GetDeviceInfo(input_param.device)
            if input_info.null?
                PA.Pa_Terminate
                raise Error::PortAudioError.new('Error getting device info')
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
                raise Error::PortAudioError.new('Output device not found.')
            end

            output_info = PA::Pa_GetDeviceInfo(output_param.device)
            if output_info.null?
                PA.Pa_Terminate
                raise Error::PortAudioError.new('Error getting device info')
            end
            output_info = PA::PaDeviceInfo.new(output_info)

            output_param.channelCount = wav.num_channels
            output_param.sampleFormat = SAMPLE_TYPE
            output_param.suggestedLatency = output_info.defaultHighOutputLatency
            output_param.hostApiSpecificStreamInfo = nil

            return output_param
        end

        private_class_method def self.handle_error(err, stream)
            if err == PA::PaErrorCode::PaInputOverflowed
                return
            elsif err != PA::PaErrorCode::PaNoError
                if !stream.null?
                    PA.Pa_AbortStream(stream)
                    PA.Pa_CloseStream(stream)
                end
                PA.Pa_Terminate
                raise Error::PortAudioError.new(PA.Pa_GetErrorText(err))
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

        # UTILITY FUNCTIONS

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

        # Converts audio data to 16-bit signed
        private_class_method def self.get_sample_values(samples)
            samples.map { |sample| sample.unpack('s').first }
        end

        # Calculates RMS of values in array
        private_class_method def self.rms(values)
            Math.sqrt(values.inject(0.0) {|sum, x| sum + x*x} / values.length)
        end

        # Determines whether audio slice is silent
        private_class_method def self.silent?(samples)
            SILENCE_THRESHOLD > get_sample_values(samples).max
        end
    end
end
