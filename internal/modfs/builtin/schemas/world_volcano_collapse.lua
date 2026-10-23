-- One Volcano cave event owns a countdown and the doorways still eligible
-- for collapse. The DES record indices witness their immutable positions.
local component = require("constants.component")

register.component({
    id = component.WORLD_VOLCANO_COLLAPSE,
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
        countdown_aut = {
            type = "int64",
            default = 0,
        },
        record_indices = {
            type = "list<int64>",
        },
        positions_x = {
            type = "list<int64>",
        },
        positions_y = {
            type = "list<int64>",
        },
    },
})
