-- spl-vortex.cc stores a 60-aut storm, its cast time, and cast power.
local zap_ids = require("policy.magic.effects.zaps.ids")
local state = {}

register.component{
    id = zap_ids.component.POLAR_VORTEX,
    version = 1,
    fields = {
        remaining_aut = { type = "int64", default = 0 },
        started_aut = { type = "int64", default = 0 },
        power = { type = "int64", default = 0 },
    },
}

return state
