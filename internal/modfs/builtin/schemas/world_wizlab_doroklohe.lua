-- Doroklohe's A marker owns a saved three-phase countdown. The source
-- wall records remain immutable witnesses; Akara stores the phase and
-- next absolute firing time so restore cannot replay a collapse.
local component = require("constants.component")

register.component({
    id = component.WORLD_WIZLAB_DOROKLOHE,
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
        phase = {
            type = "int64",
            default = 1,
        },
        next_aut = {
            type = "int64",
            default = 0,
        },
        wall_indices = {
            type = "list<int64>",
        },
        wall_x = {
            type = "list<int64>",
        },
        wall_y = {
            type = "list<int64>",
        },
    },
})
