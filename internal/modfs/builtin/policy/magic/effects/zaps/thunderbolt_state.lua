-- spl-damage.cc:THUNDERBOLT_LAST_KEY, AIM_KEY, and CHARGES_KEY.
local zap_ids = require("policy.magic.effects.zaps.ids")
local state = {}

register.component{
    id = zap_ids.component.THUNDERBOLT,
    version = 1,
    fields = {
        last_turn = { type = "int64", default = 0 },
        origin_x = { type = "int64", default = 0 },
        origin_y = { type = "int64", default = 0 },
        aim_x = { type = "int64", default = 0 },
        aim_y = { type = "int64", default = 0 },
        charges = { type = "int64", default = 0 },
    },
}

return state
