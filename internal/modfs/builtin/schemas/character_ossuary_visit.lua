-- The player holds this reciprocal return pointer only while inside the
-- Ossuary. The destination level itself owns the chosen source vault ID.
local component = require("constants.component")

register.component({
    id = component.PLAYER_OSSUARY_VISIT,
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
