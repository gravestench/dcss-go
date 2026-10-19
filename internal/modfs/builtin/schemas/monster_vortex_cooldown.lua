-- Source ENCH_POLAR_VORTEX_COOLDOWN prevents a fresh storm after the wind
-- stops. Keep that period on the caster, independent of the live vortex.
local component = require("constants.component")

local schema = {}

register.component({
    id = component.MONSTER_VORTEX_COOLDOWN,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
})

return schema
