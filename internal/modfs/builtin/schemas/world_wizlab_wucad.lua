-- Wucad Mu's A marker owns one saved monk timer and the seven one-shot
-- shadow messages. Statue death turns the same state into a permanent
-- suppression flag, preventing resurrection of callbacks after restore.
local component = require("constants.component")

register.component({
    id = component.WORLD_WIZLAB_WUCAD,
    version = 1,
    fields = {
        level_id = {
            type = "int64",
            default = 0,
        },
        vault_id = {
            type = "string",
            default = "",
        },
        monks_index = {
            type = "int64",
            default = 0,
        },
        death_index = {
            type = "int64",
            default = 0,
        },
        next_aut = {
            type = "int64",
            default = 0,
        },
        suppressed = {
            type = "bool",
            default = false,
        },
        message_indices = {
            type = "list<int64>",
        },
        message_spot = {
            type = "list<int64>",
        },
        message_x = {
            type = "list<int64>",
        },
        message_y = {
            type = "list<int64>",
        },
        message_done = {
            type = "list<bool>",
        },
    },
})
