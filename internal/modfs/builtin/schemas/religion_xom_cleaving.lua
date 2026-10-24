-- Cleaving persists on the player so combat and save restoration read the
-- same remaining aut. The timer is removed when its final action expires.
local component = require("constants.component")

local schema = {
    id = component.XOM_CLEAVING,
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
