-- Source DUR_EXHAUSTED is a shared player status. Keep its remaining aut in
-- one saved component so divine abilities and Berserk see the same timer.
local component = require("constants.component")

local schema = {
    id = component.PLAYER_EXHAUSTION,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
