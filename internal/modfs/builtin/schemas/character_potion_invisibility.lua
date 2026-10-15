-- Source: potion.cc:PotionInvisibility and duration-data.h:DUR_INVIS.
local component = require("constants.component")

local schema = {
    id = component.POTION_INVISIBILITY,
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
