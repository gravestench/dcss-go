-- Ecumenical Xom stimulation is a pending divine effect, not ordinary piety.
local component = require("constants.component")

local schema = {
    id = component.RELIGION_XOM,
    version = 1,
    fields = {
        pending_stimulation = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
