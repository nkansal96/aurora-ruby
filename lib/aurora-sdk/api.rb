require 'net/http'
require 'json'
require 'excon'
require_relative 'config'
require_relative 'interpret'
require_relative 'text'
require_relative 'error'
require_relative 'audio'

module Aurora
    # Top-level interface to the Aurora API
    class Api
        BASE_URL = 'https://api.auroraapi.com'
        TTS_URL = BASE_URL + '/v1/tts/'
        STT_URL = BASE_URL + '/v1/stt/'
        INTERPRET_URL = BASE_URL + '/v1/interpret/'

        # Queries the API with the provided raw WAV audio stream
        # and returns a transcript of the speech
        #
        # @param audio [Aurora::AudioFile]
        # @param stream [Boolean]
        # @param stream_source [Enumerator]
        #
        # @return [Aurora::Text]
        def self.get_stt(audio, stream = false, stream_source = nil)
            if !Aurora.config_valid?
                raise Error::InvalidConfigError
            end

            if stream
                header = true
                chunker = lambda do
                    # For the first chunk, send a phony WAV header with maximum length
                    if header
                        header = false
                        Aurora::Audio.create_wav('', 0xFFFFFFFF)
                    else
                        begin
                            stream_source.next
                        rescue StopIteration
                            # Must send an empty chunk to signify end of stream
                            ''
                        end
                    end
                end

                response = (Excon.post(STT_URL, :request_block => chunker, :headers => create_header_hash)).data
            else
                if !audio.is_a?(AudioFile)
                    raise Error::AudioTypeError.new(audio.class)
                end

                uri = URI(STT_URL)
                request = create_request(uri, 'POST')
                request.body = audio.to_wav

                response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) {|http|
                    http.request(request)
                }
            end

            handle_error(response, stream)

            json = JSON.parse(stream ? response[:body] : response.body)
            Text.new(json['transcript'])
        end

        # Queries the API with the provided text and returns a speech
        # object that can access the synthesized speech audio file
        #
        # @example Play the synthesized speech
        #   get_tts("Hello World").audio.play
        #
        # @param text [String]
        #
        # @return [Aurora::Speech]
        #
        def self.get_tts(text)
            if !Aurora.config_valid?
                raise Error::InvalidConfigError
            else
                uri = URI(TTS_URL)
                uri.query = URI.encode_www_form({ text: text })
                request = create_request(uri)
                response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) {|http|
                    http.request(request)
                }

                handle_error(response)

                audio_file = AudioFile.new(response.body)
                Speech.new(audio_file)
            end
        end

        # Queries the API with the provided text and returns the interpreted response.
        #
        # @param text [Aurora::Text]
        #
        # @return [Aurora::Interpret]
        def self.get_interpret(text)
            if !Aurora.config_valid?
                raise Error::InvalidConfigError
            else
                uri = URI(INTERPRET_URL)
                uri.query = URI.encode_www_form({ text: text })
                request = create_request(uri)
                response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) {|http|
                    http.request(request)
                }

                handle_error(response)

                json = JSON.parse(response.body)
                Interpret.new(json['text'], json['intent'], json['entities'])
            end
        end

        private_class_method def self.create_request(uri, type='GET')
            case type
            when 'GET' then
                req = Net::HTTP::Get.new(uri)
            when 'POST' then
                req = Net::HTTP::Post.new(uri)
            end

            req['X-Application-ID'] = Aurora.config.app_id
            req['X-Application-Token'] = Aurora.config.app_token
            req['X-Device-ID'] = Aurora.config.device_id

            return req
        end

        # Excon requires headers to be passed as a hash
        private_class_method def self.create_header_hash
            {
                'X-Application-ID' => Aurora.config.app_id,
                'X-Application-Token' => Aurora.config.app_token,
                'X-Device-ID' => Aurora.config.device_id
            }
        end

        private_class_method def self.handle_error(response, stream = false)
            if stream
                if response[:status] == 200
                    return true
                else
                    raise Error::APIError.new(response[:status_line])
                end
            end

            case response
            when Net::HTTPSuccess then
                return true
            else
                if response.body != nil
                    json = JSON.parse(response.body)
                    code = json['code']
                    msg = json['message']
                    if code != nil
                        raise Error::APIError.new("#{json['code']}: #{json['message']}")
                    else
                        raise Error::APIError.new("#{json['message']}")
                    end
                end
                raise Error::APIError
            end
        end
    end
end
