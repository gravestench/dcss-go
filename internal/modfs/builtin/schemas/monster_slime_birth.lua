-- A new body born from an ordinary slime split is outside the floor's
-- initial monster budget. Its birth time lets save validation reject a
-- forged future origin without retaining a parent that may later die.
local component = require("constants.component")

local schema = {
    id = component.SLIME_BIRTH,
    version = 1,
    fields = {
        created_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
