-- Source: actor.cc direct constriction state and monster.cc:attempt_escape.
local component = require("constants.component")

local schema = {
    id = component.PLAYER_CONSTRICTION,
    version = 1,
    fields = {
        by = {
            type = "entity",
        },

        held_aut = {
            type = "int64",
            default = 0,
        },

        escape_attempts = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
