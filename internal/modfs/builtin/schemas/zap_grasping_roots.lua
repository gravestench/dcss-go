-- spl-monench.cc:ENCH_GRASPING_ROOTS and player constriction power.
local component = require("constants.component")

local roots = {}

register.component{
    id = component.GRASPING_ROOTS,
    version = 1,
    fields = {
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
