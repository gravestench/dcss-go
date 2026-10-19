-- terrain.cc:temp_change_terrain; shared by rain and temporary summons.
local component = require("constants.component")

register.component({
    id = component.TEMPORARY_TERRAIN,
    version = 1,
    -- Original and changed features remain paired until expiry restores the authored terrain cell.
    fields = {
        source_actor_id = {
            type = "uint64",
            default = 0,
        },
        source_kind_id = {
            type = "string",
            default = "",
        },
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
        original_feature = {
            type = "string",
            default = "",
        },
        changed_feature = {
            type = "string",
            default = "",
        },
        expires_aut = {
            type = "int64",
            default = 0,
        },
    },
})
