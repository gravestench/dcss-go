-- A temporary Arena visit retains the exact return cell and authored map.
-- Duel identity belongs to a separate monster component so a revived body
-- can inherit it without copying a mutable player record.
local component = require("constants.component")

register.component({
    id = component.PLAYER_ARENA_VISIT,
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
        target_id = {
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
        exit_x = {
            type = "int64",
            default = 0,
        },
        exit_y = {
            type = "int64",
            default = 0,
        },
        victory = {
            type = "bool",
            default = false,
        },
        return_aut = {
            type = "int64",
            default = 0,
        },
    },
})
