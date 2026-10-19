local component = require("constants.component")

-- Source ENCH_EMPOWERED_SPELLS adds five spell HD and a second chance to
-- choose a spell. This recipient state survives saves and ages on its actor.
local empowered = {
    id = component.MONSTER_EMPOWERED_SPELLS,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(empowered)

return empowered
