-- A lodged barb is actor state, rather than a property of the projectile.
-- Source: beam.cc applies DUR_BARBS or ENCH_BARBS after a damaging hit.
local component = require("constants.component")

local schema = {
    id = component.BARBS,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },

        power = {
            type = "int64",
            default = 0,
        },

        source = {
            type = "entity",
        },
    },
}

register.component(schema)

return schema
