-- Source: player.h:vampire_alive and delay.cc blood rituals.
local component = require("constants.component")

local schema = {
    id = component.VAMPIRE,
    version = 1,
    fields = {
        alive = {
            type = "bool",
            default = true,
        },

        ritual_kind = {
            type = "string",
            default = "",
        },

        ritual_remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
