-- A spectral weapon is a saved actor commanded by its owner's melee turn.
local component = require("constants.component")

local schema = {
    id = component.SPECTRAL_WEAPON,
    version = 1,
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
