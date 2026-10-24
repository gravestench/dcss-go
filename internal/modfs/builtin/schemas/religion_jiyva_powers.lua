-- Jiyva's two active durations belong to the player across saves and
-- floor changes. The wall markers separately retain original terrain.
local component = require("constants.component")

local schema = {
    id = component.JIYVA_POWERS,
    version = 1,
    fields = {
        oozemancy_aut = {
            type = "int64",
            default = 0,
        },
        ooze_level_id = {
            type = "int64",
            default = 0,
        },
        slimify_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
