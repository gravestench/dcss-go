-- cloud.cc:cloud_struct as a saved, location-bound Lua entity.
local component = require("constants.component")
local state = {}

register.component{
    id = component.CLOUD,
    version = 1,
    fields = {
        kind_id = { type = "string", default = "" },
        owner = { type = "entity" },
        level_id = { type = "int64", default = 0 },
        x = { type = "int64", default = 0 },
        y = { type = "int64", default = 0 },
        expires_aut = { type = "int64", default = 0 },
    },
}

return state
