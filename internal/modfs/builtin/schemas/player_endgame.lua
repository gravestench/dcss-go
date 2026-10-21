-- The source player chapter persists separately from inventory. Taking the
-- Orb consumes its floor item and changes this single saved player value.
local component = require("constants.component")
local phases = require("constants.endgame")

local schema = {
    id = component.PLAYER_ENDGAME,
    version = 1,
    fields = {
        phase = {
            type = "string",
            default = phases.EXPLORING,
        },
    },
}

register.component(schema)

return schema
