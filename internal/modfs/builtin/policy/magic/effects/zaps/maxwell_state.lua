-- Example: ctx:get(player, zap_ids.component.MAXWELL) reads the charging timer.
-- spl-damage.cc:COUPLING_TIME_KEY and corpse suppression on discharge.
local zap_ids = require("policy.magic.effects.zaps.ids")
local state = {}

register.component{
    id = zap_ids.component.MAXWELL,
    version = 1,
    fields = {
        remaining_aut = { type = "int64", default = 0 },
    },
}

register.component{
    id = zap_ids.component.MAXWELL_VAPORIZE,
    version = 1,
    fields = {
        active = { type = "bool", default = false },
    },
}

return state
