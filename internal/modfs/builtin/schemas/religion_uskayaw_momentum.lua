-- Uskayaw's damage pool belongs to the player and survives a save made
-- between contact and the end-of-turn reaction. Lua modules hold no run
-- state, so loading a mod never resets earned dance momentum.
local component = require("constants.component")

local schema = {
    id = component.RELIGION_USKAYAW_MOMENTUM,
    version = 1,
    fields = {
        num_hurt = {
            type = "int64",
            default = 0,
        },
        hurt_value = {
            type = "int64",
            default = 0,
        },
        aut_since_gain = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
