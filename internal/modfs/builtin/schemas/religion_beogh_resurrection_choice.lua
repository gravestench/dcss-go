-- Confirming Resurrection must refer to the same corpse after save/restore.
local component = require("constants.component")

local schema = {
    id = component.BEOGH_RESURRECTION_CHOICE,
    version = 1,
    fields = {
        corpse = { type = "entity" },
    },
}

register.component(schema)

return schema
