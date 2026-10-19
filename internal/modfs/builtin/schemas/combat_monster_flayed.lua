-- Flay's victim owns its recoverable HP and duration. This survives saves
-- while the ghost, target, and ordinary HP may change independently.
-- Source: mon-cast.cc:_flay and mon-death.cc:heal_flayed_effect.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_FLAYED,
    version = 1,
    fields = {
        source = {
            type = "entity",
        },

        remaining_aut = {
            type = "int64",
            default = 0,
        },

        recoverable_hp = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
