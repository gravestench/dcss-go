-- A moving monster owns the remaining lifetime of its Silence field;
-- the field's cells are derived from its position and this saved timer.
-- Source: areas.cc:monster::silence_radius and mon-ench.cc:ENCH_SILENCE.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_SILENCE,
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
