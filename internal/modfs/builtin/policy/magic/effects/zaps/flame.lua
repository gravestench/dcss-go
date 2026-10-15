local spells = require("ids.spells")
local projectile = require("policy.magic.effects.zaps.projectile")

local flame = {}

-- Source: zap-data.h:ZAP_THROW_FLAME, BEAM_FIRE at pinned revision.
flame.spec = {
    name = "puff of flame",
    cap = 50,
    damage = {
        kind = "dicedef",
        count = 2,
        base = 4,
        numerator = 1,
        denominator = 10,
    },
    hit = {
        base = 8,
        numerator = 1,
        denominator = 10,
    },
    element = "MR_RES_FIRE",
}

projectile.register(spells.SPELL_THROW_FLAME, flame.spec)

return flame
