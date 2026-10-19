-- Source: player.cc:player::sentinel_mark. The timer survives save/restore.
local component = require("constants.component")

local schema = {
    id = component.TRAP_MARK,
    version = 1,
    -- The mark timer remains on the target until it expires or its sentinel responds.
    fields = {
        remaining_aut = {
            type = "int64",
        },
    },
}

register.component(schema)

return schema
