module Aurora
    class Text
        attr_accessor :text

        def initialize(text)
            @text = text
        end

        # Convert text to speech
        def to_speech
            Aurora::Api.get_tts(@text)
        end

        # Interpret the text and return the results
        def to_interpret
            Aurora::Api.get_interpret(@text)
        end

    end
end
