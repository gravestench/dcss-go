-- Source MF_TSO_SEEN remembers that a monster already offered first-sight
-- conduct. It survives leaving sight and save/restore, unlike the temporary
-- visibility marker used by shout and message systems.
local component = require("constants.component")

local schema = {
    id = component.RELIGION_TSO_SEEN,
    version = 1,
    fields = {
        seen = {
            type = "bool",
            default = true,
        },
    },
}

register.component(schema)

return schema
