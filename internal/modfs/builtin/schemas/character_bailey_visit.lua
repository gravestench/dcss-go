-- The player holds this reciprocal return pointer only while inside the
-- Bailey. The destination level itself owns the chosen source vault ID.
local component = require("constants.component")

register.component({
    id = component.PLAYER_BAILEY_VISIT,
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

        theme = {
            type = "string",
            default = "",
        },
    },
})
