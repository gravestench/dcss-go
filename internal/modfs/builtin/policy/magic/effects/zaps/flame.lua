-- Example: flame.spec supplies Throw Flame's damage and hit formula to projectile.register.
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

-- Throw Flame registers a short fire projectile with the shared player zap resolver.
projectile.register(spells.SPELL_THROW_FLAME, flame.spec)

return flame
