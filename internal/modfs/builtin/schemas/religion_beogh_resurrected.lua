-- A new actor from a corpse has an explicit source for save validation.
local component = require("constants.component")

local schema = {
    id = component.BEOGH_RESURRECTED,
    version = 1,
    fields = {
        created_aut = { type = "int64", default = 0 },
    },
}

register.component(schema)

return schema
