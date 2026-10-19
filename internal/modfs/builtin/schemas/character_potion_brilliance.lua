-- Source: potion.cc:PotionBrilliance and spl-util.cc:spell_mana.
local component = require("constants.component")

local schema = {
    id = component.POTION_BRILLIANCE,
    version = 1,
    -- Spell cost and power checks read the same remaining brilliance duration.
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
