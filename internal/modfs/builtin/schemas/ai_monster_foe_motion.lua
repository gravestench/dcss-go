-- A monster remembers where it last saw its foe. This is the ECS form
-- of source FOE_APPROACHING_KEY used by defensive plant placement.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_FOE_MOTION,
    version = 1,
    fields = {
        foe_id = {
            type = "int64",
            default = 0,
        },
        x = {
            type = "int64",
            default = 0,
        },
        y = {
            type = "int64",
            default = 0,
        },
        approaching = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema
