-- One Bailey gate owns one saved ECS countdown. The source marker and level
-- grid remain separate evidence so restore can reject a forged deadline.
local component = require("constants.component")

register.component({
    id = component.WORLD_BAILEY_PORTAL,
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

        -- The source chooses the theme once. This saved field determines
        -- the destination pool even after a mod layer changes the catalog.
        theme = {
            type = "string",
            default = "",
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

        -- Entry and natural expiry leave the same stone arch. This saved
        -- reason preserves which event closed the gate after the visit.
        closure_reason = {
            type = "string",
            default = "",
        },

        announced = {
            type = "bool",
            default = false,
        },

        -- Source timed_msg starts checking after fifty turns, then saves
        -- the next check after each noise. This survives save/restore.
        next_notice_aut = {
            type = "int64",
            default = 0,
        },

        final_warning = {
            type = "bool",
            default = false,
        },
    },
})
