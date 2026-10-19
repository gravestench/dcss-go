-- Killed Doom Howl beasts can grant ordinary XP although they never
-- occupied a slot in the level's initial population budget.
local ids = require("policy.combat.monster_doom_howl.ids")

local schema = {
    id = ids.REWARDS,
    version = 1,
    fields = {
        earned_xp = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
