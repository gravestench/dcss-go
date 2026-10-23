-- The player keeps the exact outside gate while inside one Desolation.
-- Every authored exit arch uses this pointer, so return never depends on
-- which arch happens to appear first in the source MAP.
local component = require("constants.component")

register.component({
    id = component.PLAYER_DESOLATION_VISIT,
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
    },
})
