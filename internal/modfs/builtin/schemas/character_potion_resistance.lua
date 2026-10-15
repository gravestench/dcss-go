-- Source: potion.cc:PotionResistance and player.cc:DUR_RESISTANCE.
local component = require("constants.component")

local schema = {
    id = component.POTION_RESISTANCE,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
