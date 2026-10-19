-- Source behold.cc stores a player timer, beholder identities, and a short
-- immunity after the last beholder stops. All three must survive a save.
local component = require("constants.component")

local schema = {
    id = component.PLAYER_MESMERISM,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
        immune_aut = {
            type = "int64",
            default = 0,
        },
        sources = {
            type = "list<entity>",
        },
    },
}

register.component(schema)

return schema
