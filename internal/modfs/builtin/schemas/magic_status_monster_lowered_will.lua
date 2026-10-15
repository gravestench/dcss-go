-- Source: monster.cc:monster::willpower and mon-ench.cc:ENCH_LOWERED_WL.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_LOWERED_WILL,
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
