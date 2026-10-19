-- A spectral weapon is a saved actor commanded by its owner's melee turn.
local component = require("constants.component")

local schema = {
    id = component.SPECTRAL_WEAPON,
    version = 1,
    -- The summoned weapon retains its source item and the aut of its last owner-triggered attack.
    fields = {
        source_weapon = {
            type = "entity",
        },

        triggered_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
