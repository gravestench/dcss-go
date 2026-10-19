-- Example: ctx:get(orb, zap_ids.component.IOOD) reads homing velocity and target.
-- mon-project.cc:IOOD_X/Y/VX/VY/DIST/POW and the homing foe.
local zap_ids = require("policy.magic.effects.zaps.ids")
local state = {}

register.component{
    id = zap_ids.component.IOOD,
    version = 1,
    fields = {
        x = { type = "float64", default = 0 },
        y = { type = "float64", default = 0 },
        vx = { type = "float64", default = 0 },
        vy = { type = "float64", default = 0 },
        distance = { type = "int64", default = 0 },
        power = { type = "int64", default = 0 },
        target = { type = "entity" },
    },
}

return state
