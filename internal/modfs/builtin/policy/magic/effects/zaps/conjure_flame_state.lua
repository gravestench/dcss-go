-- Example: ctx:get(cell, zap_ids.component.CONJURE_FLAME) reads the pending ignition timer.
-- spl-clouds.cc:CFLAME_DUR_KEY follows the saved ember cloud entity.
local zap_ids = require("policy.magic.effects.zaps.ids")
local state = {}

register.component{
    id = zap_ids.component.CONJURE_FLAME,
    version = 1,
    fields = {
        fire_duration_aut = { type = "int64", default = 0 },
    },
}

return state
