-- The player owns the echo and its next call countdown. Both survive a save
-- so leaving and returning cannot reroll or skip a pending beast arrival.
local ids = require("policy.combat.monster_doom_howl.ids")

local schema = {
    id = ids.PLAYER_DOOM_HOWL,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },

        next_call_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
