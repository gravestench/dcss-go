-- Source: potion.cc:PotionResistance and player.cc:DUR_RESISTANCE.
local component = require("constants.component")

local schema = {
    id = component.POTION_RESISTANCE,
    version = 1,
    -- One timed resistance state serves every elemental resistance check after the potion is consumed.
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
