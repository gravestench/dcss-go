-- Source: player.cc lives, deaths, max_level and ATTR_LIFE_GAINED.
local component = require("constants.component")

local schema = {
    id = component.EXTRA_LIVES,
    version = 1,
    -- Historical max level and last award level prevent repeat Felid life grants after death and level loss.
    fields = {
        lives = {
            type = "int64",
            default = 0,
        },
        deaths = {
            type = "int64",
            default = 0,
        },
        max_level = {
            type = "int64",
            default = 1,
        },
        last_life_gained = {
            type = "int64",
            default = 0,
        },
        pending_revival = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema
