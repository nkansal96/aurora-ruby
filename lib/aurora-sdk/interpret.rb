module Aurora
    class Interpret
        attr_accessor :text, :intent, :entities

        # @param text [String]
        # @param intent [String]
        # @param entities [Hash]
        #
        # @return a new instance of Aurora::Interpret
        def initialize(text, intent, entities)
            @text = text
            @intent = intent
            @entities = entities
        end
    end
end
