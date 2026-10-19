-- Source fearmonger.cc stores both a duration and the monsters that cause
-- it. ECS references keep that relationship in saves instead of Lua globals.
local component = require("constants.component")

local schema = {
    id = component.PLAYER_FEAR,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
        sources = {
            type = "list<entity>",
        },
    },
}

register.component(schema)

return schema
