-- While inside Volcano, the player owns the exact outside return pointer.
-- Removing this component finishes one temporary visit.
local component = require("constants.component")

register.component({
    id = component.PLAYER_VOLCANO_VISIT,
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
