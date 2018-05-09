require 'net/http'
require 'json'
require_relative 'aurora-sdk/config'
require_relative 'aurora-sdk/interpret'
require_relative 'aurora-sdk/error'

module Aurora

    class << self
        attr_accessor :config
    end

    # Sends text to language interpreter
    def self.get_interpret(text)
        if config == nil
            raise NilConfigError
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

    private

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

    def self.create_request(uri)
        req = Net::HTTP::Get.new(uri)
        req['X-Application-ID'] = config.app_id
        req['X-Application-Token'] = config.app_token
        req['X-Device-ID'] = config.device_id
        return req
    end
end
