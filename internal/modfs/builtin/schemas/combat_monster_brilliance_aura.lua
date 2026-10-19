local component = require("constants.component")

-- The aura caster and its recipients own distinct durations. A recipient
-- retains a short spell boost if the caster leaves or dies after pulsing.
local aura = {
    id = component.MONSTER_BRILLIANCE_AURA,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(aura)

return aura
