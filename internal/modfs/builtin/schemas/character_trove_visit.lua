-- The player owns the precise outside address of an active Treasure Trove
-- visit. Return removes this component and retires the temporary floor.
local component = require("constants.component")

register.component({
    id = component.PLAYER_TROVE_VISIT,
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
