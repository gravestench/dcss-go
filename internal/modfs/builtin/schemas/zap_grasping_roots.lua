-- spl-monench.cc:ENCH_GRASPING_ROOTS and player constriction power.
local component = require("constants.component")

local roots = {}

register.component{
    id = component.GRASPING_ROOTS,
    version = 2,
    -- Root power, hold time, and escape attempts stay together for later constriction checks.
    fields = {
        -- Caster identity drives later constriction damage and death cleanup.
        source = {
            type = "entity",
        },

        remaining_aut = {
            type = "int64",
            default = 0,
        },
        power = {
            type = "int64",
            default = 0,
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

return roots
