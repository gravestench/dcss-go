-- The visitor owns the exact outside coordinate while on the temporary
-- Gauntlet floor. Any authored return arch uses this one saved pointer.
local component = require("constants.component")

register.component({
    id = component.PLAYER_GAUNTLET_VISIT,
    version = 1,
    fields = {
        origin_level_id = {
            type = "int64",
            default = 0,
        },

        origin_x = {
            type = "int64",
            default = 0,
        },

        origin_y = {
            type = "int64",
            default = 0,
        },

        level_id = {
            type = "int64",
            default = 0,
        },

        vault_id = {
            type = "string",
            default = "",
        },
    },
})
