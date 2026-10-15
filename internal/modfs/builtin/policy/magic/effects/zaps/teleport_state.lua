-- teleport.cc:ENCH_TP delayed monster teleport.
local component = require("constants.component")
local state = {}

register.component{
    id = component.TELEPORT,
    version = 1,
    fields = {
        remaining_aut = { type = "int64", default = 0 },
    },
}

return state
