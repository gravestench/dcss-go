-- One realized entrance owns one Akara clock. The DES marker remains the
-- source witness used by save validation; this component is mutable state.
local component = require("constants.component")

register.component({
    id = component.WORLD_ICE_CAVE_PORTAL,
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

        hard = {
            type = "bool",
            default = false,
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

        closure_reason = {
            type = "string",
            default = "",
        },

        announced = {
            type = "bool",
            default = false,
        },

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
