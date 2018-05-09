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

        HTTP_ERRORS = [
            EOFError,
            Errno::ECONNRESET,
            Errno::EINVAL,
            Net::HTTPClientError,
            Net::HTTPBadResponse,
            Net::HTTPHeaderSyntaxError,
            Net::ProtocolError,
            Timeout::Error
        ]

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

                case response
                when Net::HTTPSuccess then
                    # TODO: convert to a Speech object
                    response.body
                when *HTTP_ERRORS then
                    if response.body != nil
                        json = JSON.parse(response.body)
                        msg = "#{json['code']}: #{json['message']}"
                        raise APIError.new(msg)
                    end
                else
                    raise APIError
                end
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

                case response
                when Net::HTTPSuccess then
                    json = JSON.parse(response.body)
                    Interpret.new(json['text'], json['intent'], json['entities'])
                when *HTTP_ERRORS then
                    if response.body != nil
                        json = JSON.parse(response.body)
                        msg = "#{json['code']}: #{json['message']}"
                        raise APIError.new(msg)
                    end
                else
                    raise APIError
                end
            end
        end

        private_class_method def self.create_request(uri)
            req = Net::HTTP::Get.new(uri)
            req['X-Application-ID'] = Aurora.config.app_id
            req['X-Application-Token'] = Aurora.config.app_token
            req['X-Device-ID'] = Aurora.config.device_id
            return req
        end
    end
end
