-- Source: player.cc:player::sentinel_mark. The timer survives save/restore.
local component = require("constants.component")

local schema = {
    id = component.TRAP_MARK,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
        },
    },
}

register.component(schema)

return schema
