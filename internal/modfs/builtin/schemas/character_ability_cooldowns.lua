local component = require("constants.component")

local schema = {
    id = component.ABILITY_COOLDOWNS,
    version = 1,
    -- Hop and Word of Chaos have separate aut timers because using either ability must not reset the other.
    fields = {
        hop_aut = {
            type = "int64",
            default = 0,
        },
        word_of_chaos_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
