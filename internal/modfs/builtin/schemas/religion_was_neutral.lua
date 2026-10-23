-- Source MF_WAS_NEUTRAL survives a monster becoming hostile. A good god
-- still remembers that former peaceful status during later attacks.
local component = require("constants.component")

local schema = {
    id = component.RELIGION_WAS_NEUTRAL,
    version = 1,
    fields = {
        remembered = {
            type = "bool",
            default = true,
        },
    },
}

register.component(schema)

return schema
