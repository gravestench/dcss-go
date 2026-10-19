-- The source marks a Doom Hound after its first howl, even when the player
-- echo later expires. This component persists that one-use decision.
local ids = require("policy.combat.monster_doom_howl.ids")

local schema = {
    id = ids.MONSTER_DOOM_HOWLED,
    version = 1,
    fields = {
        used = {
            type = "bool",
            default = true,
        },
    },
}

register.component(schema)

return schema
