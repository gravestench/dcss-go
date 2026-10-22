-- A source Bazaar marker owns the entrance's countdown and one-way use.
-- Keeping it on an ECS entity makes timer and spent state survive saves.
local component = require("constants.component")

register.component({
    id = component.WORLD_BAZAAR_PORTAL,
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
        low = {
            type = "int64",
            default = 0,
        },
        high = {
            type = "int64",
            default = 0,
        },
        expires_aut = {
            type = "int64",
            default = 0,
        },
        created_aut = {
            type = "int64",
            default = 0,
        },
        timed = {
            type = "bool",
            default = false,
        },
        spent = {
            type = "bool",
            default = false,
        },
    },
})
