local component = require("constants.component")
local stats = require("constants.stats")

-- Source: player-stats.cc stores temporary loss separately from base stats.
local schema = {
    id = component.STAT_LOSS,
    version = 1,
    fields = {
        [stats.STRENGTH] = {
            type = "int64",
            default = 0,
        },
        [stats.INTELLIGENCE] = {
            type = "int64",
            default = 0,
        },
        [stats.DEXTERITY] = {
            type = "int64",
            default = 0,
        },
        remaining_xp = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
