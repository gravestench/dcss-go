-- Roll persists on the beetle between the self cast, movement, and its
-- next melee strike. Source: mon-cast.cc and mon-ench.cc:ENCH_ROLLING.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_ROLLING,
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
