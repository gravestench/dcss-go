-- A source player-move marker becomes one saved, one-shot ECS entity.
-- Its callback identity is stable across save/restore and mod layers.
local component = require("constants.component")

register.component({
    id = component.WORLD_VAULT_TRIGGER,
    version = 4,
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
        callback_module = {
            type = "string",
            default = "",
        },
        callback_method = {
            type = "string",
            default = "",
        },
        -- The same saved marker owner can fire on entry or on a named
        -- monster's death; its callback decides when to consume itself.
        event = {
            type = "string",
            default = "enter",
        },
        target_x = {
            type = "int64",
            default = 0,
        },
        target_y = {
            type = "int64",
            default = 0,
        },
        -- One explicit group joins several source trigger cells. Record
        -- links and final coordinates let the callback act on oriented
        -- walls and let save validation detect partial or forged changes.
        group_id = {
            type = "string",
            default = "",
        },
        wall_record_indices = {
            type = "list<int64>",
            default = {},
        },
        wall_x = {
            type = "list<int64>",
            default = {},
        },
        wall_y = {
            type = "list<int64>",
            default = {},
        },
    },
})
