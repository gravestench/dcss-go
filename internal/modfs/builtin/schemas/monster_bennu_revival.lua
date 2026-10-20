-- A Bennu gets one rebirth. The count belongs to the new ECS body so
-- save/restore cannot mistake its next death for its first one.
local component = require("constants.component")

local schema = {
    id = component.BENNU_REVIVAL,
    version = 1,
    fields = {
        revives = {
            type = "uint64",
        },
    },
}

register.component(schema)

return schema
