-- Each realized Wizard Lab entrance is one ECS clock. Its source DES
-- marker stores the duration draw, while this component stores the
-- deadline and one-time message/closure state across save and restore.
local component = require("constants.component")

register.component({
    id = component.WORLD_WIZLAB_PORTAL,
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
        final_warning = {
            type = "bool",
            default = false,
        },
    },
})
