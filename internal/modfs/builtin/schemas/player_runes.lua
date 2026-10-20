-- Runes are run progress, not inventory stacks. A collected rune remains
-- owned by the player even if its floor item entity is destroyed.
local component = require("constants.component")

local schema = {
    id = component.PLAYER_RUNES,
    version = 1,
    fields = {
        collected = {
            type = "map<string,bool>",
        },
    },
}

register.component(schema)

return schema
