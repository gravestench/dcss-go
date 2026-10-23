-- Zin speaks once per action when repeated effects add to an existing glow.
-- The last absolute game time lives on the player across save and restore.
local component = require("constants.component")

local schema = {
    id = component.RELIGION_ZIN_GLOW_LECTURE,
    version = 1,
    fields = {
        last_aut = {
            type = "int64",
            default = -1,
        },
    },
}

register.component(schema)

return schema
