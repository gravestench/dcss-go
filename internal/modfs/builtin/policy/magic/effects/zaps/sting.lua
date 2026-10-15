local spells = require("ids.spells")
local projectile = require("policy.magic.effects.zaps.projectile")

local sting = {}

-- zap-data.h:ZAP_STING; beam.cc:BEAM_POISON_ARROW supplies forced poison.
sting.spec = {
    name = "sting",
    cap = 25,
    damage = {
        kind = "dicedef",
        count = 1,
        base = 3,
        numerator = 1,
        denominator = 5,
    },
    hit = {
        base = 8,
        numerator = 1,
        denominator = 5,
    },
    ac_rule = "normal",
    poison_arrow = true,
}

projectile.register(spells.SPELL_STING, sting.spec)

return sting
