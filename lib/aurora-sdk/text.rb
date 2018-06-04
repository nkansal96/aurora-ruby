module Aurora
    class Text
        attr_accessor :text

        # @param text String object
        #
        # @return Aurora::Text object
        def initialize(text)
            @text = text
        end

        # Converts the text to synthesized speech
        #
        # @example Play the synthesized speech
        #   Aurora::Text.new("Hello World").to_speech.audio.play
        #
        # @return Aurora::Speech object
        def to_speech
            Aurora::Api.get_tts(@text)
        end

        # Interpret the text and returns the interpreted response
        #
        # @return Aurora::Interpret object
        def to_interpret
            Aurora::Api.get_interpret(@text)
        end

    end
end
