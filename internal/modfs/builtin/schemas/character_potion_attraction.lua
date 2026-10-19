-- Source: potion.cc:PotionAttraction and player-reacts.cc.
local component = require("constants.component")

local schema = {
    id = component.POTION_ATTRACTION,
    version = 1,
    -- The attraction status persists beyond the drink action for later monster movement decisions.
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
