require 'net/http'
require 'json'
require_relative 'config'
require_relative 'interpret'
require_relative 'text'
require_relative 'error'

module Aurora
    class Api
        BASE_URL = 'https://api.auroraapi.com'
        TTS_URL = BASE_URL + '/v1/tts/'
        STT_URL = BASE_URL + '/v1/stt/'
        INTERPRET_URL = BASE_URL + '/v1/interpret/'

        def self.get_stt(audio, stream = false)
            if !Aurora.config_valid?
                raise InvalidConfigError
            else
                if stream
                    # TODO: implement audio stream for continuous functions
                    return
                else
                    if !audio.is_a?(AudioFile)
                        raise AudioTypeError.new(audio.class)
                    end
                    data = audio.to_wav
                end

                uri = URI(STT_URL)
                request = create_request(uri, 'POST')
                request.body = data
                response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) {|http|
                    http.request(request)
                }

                handle_error(response)

                # Return Text object
                json = JSON.parse(response.body)
                Text.new(json['transcript'])
            end
        end

        def self.get_tts(text)
            if !Aurora.config_valid?
                raise InvalidConfigError
            else
                uri = URI(TTS_URL)
                uri.query = URI.encode_www_form({ text: text })
                request = create_request(uri)
                response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) {|http|
                    http.request(request)
                }

                handle_error(response)

                # Return Speech object
                audio_file = AudioFile.new(response.body)
                Speech.new(audio_file)
            end
        end

        def self.get_interpret(text)
            if !Aurora.config_valid?
                raise InvalidConfigError
            else
                uri = URI(INTERPRET_URL)
                uri.query = URI.encode_www_form({ text: text })
                request = create_request(uri)
                response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) {|http|
                    http.request(request)
                }

                handle_error(response)

                # Return Interpret object
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

        private_class_method def self.handle_error(response)
            case response
            when Net::HTTPSuccess then
                return true
            else
                if response.body != nil
                    json = JSON.parse(response.body)
                    code = json['code']
                    msg = json['message']
                    if code != nil
                        raise APIError.new("#{json['code']}: #{json['message']}")
                    else
                        raise APIError.new("#{json['message']}")
                    end
                end
                raise APIError
            end
        end
    end
end
