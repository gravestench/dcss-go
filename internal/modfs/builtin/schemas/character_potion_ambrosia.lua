-- Source: potion.cc:PotionAmbrosia and player.cc:dec_ambrosia_player.
local component = require("constants.component")

local schema = {
    id = component.POTION_AMBROSIA,
    version = 1,
    -- Ambrosia recovery reads an aut timer so partial turns do not skip its remaining healing window.
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
