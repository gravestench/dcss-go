-- Source: duration-data.h:DUR_TELEPORT and spl-transloc.cc:you_teleport.
local component = require("constants.component")

local schema = {
    id = component.PLAYER_TELEPORT,
    version = 1,
    -- Delayed teleport survives a save between the trigger and the eventual relocation.
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
