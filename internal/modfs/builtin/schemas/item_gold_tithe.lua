-- The gold entity remembers Zin's source sighting and acquirement facts.
-- The wallet keeps paid donations and the remainder between small piles.
local component = require("constants.component")
local states = require("constants.zin_tithe_state")

local schema = {
    id = component.GOLD_TITHE,
    version = 1,
    fields = {
        state = {
            type = "string",
            default = states.DEFAULT,
        },

        acquired = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema
