require 'json'

module Aurora
    class Interpret
        attr_reader :text, :intent, :entities

        def initialize(text, intent, entities)
            @text = text
            @intent = intent
            @entities = entities
        end
    end
end
