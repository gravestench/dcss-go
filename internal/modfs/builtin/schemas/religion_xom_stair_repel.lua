-- Xom's two stair timers belong to the player and survive save/restore.
-- Moving stairs last 100 turns; the climb refusal lasts only 50 turns.
local component = require("constants.component")

local schema = {
    id = component.XOM_STAIR_REPEL,
    version = 1,
    fields = {
        move_aut = {
            type = "int64",
            default = 0,
        },

        climb_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
