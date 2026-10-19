-- A marked monster carries its own melee proc timer across actions and saves.
-- Source: mon-ench.cc:ENCH_BLACK_MARK.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_BLACK_MARK,
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
