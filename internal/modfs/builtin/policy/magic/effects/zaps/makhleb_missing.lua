-- These player zap profiles are required by Makhleb's random powers and
-- also fill gaps in ordinary spell casting. Values come from the player
-- half of pinned zap-data.h; source Breathe Acid is distinct from Spit Acid.
local drain = require("policy.combat.monster_drain")
local enchant = require("policy.combat.monster_enchant")
local projectile = require("policy.magic.effects.zaps.projectile")
local resistances = require("constants.resistance_ids")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local profiles = {}

-- Bolt of Draining applies the shared monster drain only after a damaging
-- contact; the beam owner handles its piercing path and negative resistance.
function profiles.drain(ctx, player, target, definition)
    drain.apply(ctx, target, definition, player, "spell", true)
end

-- Acid breath uses corrosion after contact, just as the existing acid
-- bolt does; this callback keeps its source dice separate from Spit Acid.
function profiles.corrode(ctx, _, target, definition)
    enchant.corrode(ctx, target, definition)
end

profiles.acid_breath = {
    name = "glob of acid",
    cap = 50,
    element = resistances.ACID,
    after_hit = profiles.corrode,
    damage = {
        kind = "dicedef",
        count = 5,
        base = 4,
        numerator = 1,
        denominator = 3,
    },
    hit = {
        base = 7,
        numerator = 1,
        denominator = 6,
    },
}

profiles.pain = {
    name = "pain",
    cap = 100,
    enchantment = true,
    element = resistances.NEGATIVE_ENERGY,
    negative_energy = true,
    ac_rule = "none",
    damage = {
        kind = "dicedef",
        count = 1,
        base = 4,
        numerator = 1,
        denominator = 5,
    },
    hit = {
        base = 0,
        numerator = 7,
        denominator = 2,
    },
}

profiles.fire = {
    name = "bolt of fire",
    cap = 200,
    beam = true,
    element = resistances.FIRE,
    damage = {
        kind = "calcdice",
        count = 6,
        base = 18,
        numerator = 2,
        denominator = 3,
    },
    hit = {
        base = 10,
        numerator = 1,
        denominator = 25,
    },
}

profiles.magma = {
    name = "bolt of magma",
    cap = 200,
    beam = true,
    element = resistances.FIRE,
    element_fraction = 55,
    damage = {
        kind = "calcdice",
        count = 4,
        base = 16,
        numerator = 2,
        denominator = 3,
    },
    hit = {
        base = 8,
        numerator = 1,
        denominator = 25,
    },
}

profiles.draining = {
    name = "bolt of negative energy",
    cap = 200,
    beam = true,
    element = resistances.NEGATIVE_ENERGY,
    negative_energy = true,
    after_hit = profiles.drain,
    damage = {
        kind = "calcdice",
        count = 4,
        base = 15,
        numerator = 3,
        denominator = 5,
    },
    hit = {
        base = 8,
        numerator = 1,
        denominator = 20,
    },
}

projectile.specs[zaps.ZAP_BREATHE_ACID] = profiles.acid_breath
projectile.register(spells.SPELL_PAIN, profiles.pain)
projectile.register(spells.SPELL_BOLT_OF_FIRE, profiles.fire)
projectile.register(spells.SPELL_BOLT_OF_MAGMA, profiles.magma)
projectile.register(spells.SPELL_BOLT_OF_DRAINING,
    profiles.draining)

return profiles
