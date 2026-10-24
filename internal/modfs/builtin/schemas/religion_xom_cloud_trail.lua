-- Xom's chosen trail cloud and remaining aut belong to the player. The
-- source leaves a new cloud on each vacated cell without rerolling the kind.
local component = require("constants.component")

local schema = {
    id = component.XOM_CLOUD_TRAIL,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },

        cloud_kind = {
            type = "string",
            default = "",
        },
    },
}

register.component(schema)

return schema
