-- A source player-move marker becomes one saved, one-shot ECS entity.
-- Its callback identity is stable across save/restore and mod layers.
local component = require("constants.component")

register.component({
    id = component.WORLD_VAULT_TRIGGER,
    version = 2,
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
        target_x = {
            type = "int64",
            default = 0,
        },
        target_y = {
            type = "int64",
            default = 0,
        },
    },
})
