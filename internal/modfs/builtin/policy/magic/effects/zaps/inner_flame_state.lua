-- Example: ctx:get(target, component.INNER_FLAME) retains the source of a pending explosion.
-- beam.cc:BEAM_INNER_FLAME and mon-explode.cc:explosion_fineff.
local component = require("constants.component")
local state = {}

register.component{
    id = component.INNER_FLAME,
    version = 1,
    fields = {
        source = { type = "entity" },
        remaining_aut = { type = "int64", default = 0 },
    },
}

return state
