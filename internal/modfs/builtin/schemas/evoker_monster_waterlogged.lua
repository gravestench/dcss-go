-- A flooded monster may be unable to vocalize until the splash dries.
-- This distinct status lets saves and UI distinguish water from Mute.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_WATERLOGGED,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
