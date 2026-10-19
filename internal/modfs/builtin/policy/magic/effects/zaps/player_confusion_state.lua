-- Example: ctx:get(player, zap_ids.component.PLAYER_CONFUSION) reads the remaining confusion time.
-- cloud.cc:CLOUD_MEPHITIC can confuse the player for two or three turns.
local zap_ids = require("policy.magic.effects.zaps.ids")
local state = {}

register.component{
    id = zap_ids.component.PLAYER_CONFUSION,
    version = 1,
    fields = {
        remaining_aut = { type = "int64", default = 0 },
    },
}

return state
