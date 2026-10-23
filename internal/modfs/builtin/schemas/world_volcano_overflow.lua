-- A single phase clock owns an overflow floor. Cell groups remain typed
-- source records; converted indices identify lava that must later harden.
local component = require("constants.component")

register.component({
    id = component.WORLD_VOLCANO_OVERFLOW,
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
        clock_index = {
            type = "int64",
            default = 0,
        },
        countdown_aut = {
            type = "int64",
            default = 0,
        },
        phase = {
            type = "int64",
            default = 0,
        },
        record_indices = {
            type = "list<int64>",
        },
        groups = {
            type = "list<int64>",
        },
        positions_x = {
            type = "list<int64>",
        },
        positions_y = {
            type = "list<int64>",
        },
        converted_indices = {
            type = "list<int64>",
        },
    },
})
