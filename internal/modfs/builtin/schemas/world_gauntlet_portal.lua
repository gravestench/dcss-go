-- Each realized Gauntlet gate is one Akara clock. Its source marker
-- holds the single duration draw; these fields retain its deadline and
-- message state across floor changes and save/restore.
local component = require("constants.component")

register.component({
    id = component.WORLD_GAUNTLET_PORTAL,
    version = 1,
    fields = {
        level_id = {
            type = "int64",
            default = 0,
        },

        x = {
            type = "int64",
            default = 0,
        },

        y = {
            type = "int64",
            default = 0,
        },

        vault_id = {
            type = "string",
            default = "",
        },

        record_index = {
            type = "int64",
            default = 0,
        },

        duration_turns = {
            type = "int64",
            default = 0,
        },

        created_aut = {
            type = "int64",
            default = 0,
        },

        expires_aut = {
            type = "int64",
            default = 0,
        },

        spent = {
            type = "bool",
            default = false,
        },

        announced = {
            type = "bool",
            default = false,
        },

        next_notice_aut = {
            type = "int64",
            default = 0,
        },
    },
})
