module Aurora
    class Interpret
        attr_accessor :text, :intent, :entities

        def initialize(text, intent, entities)
            @text = text
            @intent = intent
            @entities = entities
        end
    end
end
