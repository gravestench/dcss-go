-- A tagged actor waits through one accepted ordinary stair action.
-- The travel owner removes this mark before the action can be saved.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_STAIR_FOLLOWER,
    version = 1,
    fields = {
        taking_stairs = {
            type = "bool",
            default = false,
        },

        order = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
