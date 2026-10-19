-- Source: traps.cc player ATTR_HELD and monster ENCH_HELD.
local component = require("constants.component")

local schema = {
    id = component.TRAP_HELD,
    version = 1,
    -- The held actor stores trap kind and net item link for escape and release logic.
    fields = {
        kind_id = {
            type = "string",
        },

        net_item_id = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
