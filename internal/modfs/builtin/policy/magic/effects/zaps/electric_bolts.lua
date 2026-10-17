local spells = require("ids.spells")
local projectile = require("policy.magic.effects.zaps.projectile")
local bounce = require("policy.combat.beam_bounce")

local electric_bolts = {}

electric_bolts.bounceable = bounce.electric

electric_bolts.shock = {
    name = "zap",
    cap = 25,
    beam = true,
    bounce = electric_bolts.bounceable,
    element = "MR_RES_ELEC",
    damage = {
        kind = "dicedef",
        count = 1,
        base = 3,
        numerator = 1,
        denominator = 4,
    },
    hit = {
        base = 8,
        numerator = 1,
        denominator = 7,
    },
}

electric_bolts.lightning_bolt = {
    name = "bolt of lightning",
    cap = 200,
    beam = true,
    bounce = electric_bolts.bounceable,
    element = "MR_RES_ELEC",
    damage = {
        kind = "calcdice",
        count = 1,
        base = 11,
        numerator = 3,
        denominator = 5,
    },
    hit = {
        base = 7,
        numerator = 1,
        denominator = 40,
    },
}

projectile.register(spells.SPELL_SHOCK, electric_bolts.shock)
projectile.register(spells.SPELL_LIGHTNING_BOLT, electric_bolts.lightning_bolt)

return electric_bolts
