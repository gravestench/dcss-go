-- beam.cc:napalm_monster and mon-ench.cc:ENCH_STICKY_FLAME.
local component = require("constants.component")
local state = {}

register.component{
    id = component.STICKY_FLAME,
    version = 1,
    fields = {
        degree = {
            type = "int64",
            default = 0,
        },

        remaining_aut = {
            type = "int64",
            default = 0,
        },

        max_aut = {
            type = "int64",
            default = 0,
        },

        source = {
            type = "entity",
        },
    },
}

return state
