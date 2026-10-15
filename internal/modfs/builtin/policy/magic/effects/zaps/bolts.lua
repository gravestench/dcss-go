local spells = require("ids.spells")
local enchant = require("policy.combat.monster_enchant")
local projectile = require("policy.magic.effects.zaps.projectile")

local bolts = {}

function bolts.blind(ctx, _, target, definition)
    enchant.blind(ctx, target, definition)
end

function bolts.corrode(ctx, _, target, definition)
    enchant.corrode(ctx, target, definition)
end

function bolts.dispel(ctx, _, target, definition)
    enchant.dispel(ctx, target, definition)
end

local function bolt(name, count, base, numerator, denominator, element, effect)
    return {
        name = name,
        cap = 200,
        beam = true,
        damage = {
            kind = "calcdice",
            count = count,
            base = base,
            numerator = numerator,
            denominator = denominator,
        },
        hit = {
            base = 10,
            numerator = 1,
            denominator = 25,
        },
        ac_rule = "normal",
        element = element,
        after_hit = effect,
    }
end

-- zap-data.h player values; beam.cc applies each secondary effect on hit.
projectile.register(spells.SPELL_BOLT_OF_LIGHT, bolt(
    "bolt of light", 4, 13, 3, 5, nil, bolts.blind))

projectile.register(spells.SPELL_CORROSIVE_BOLT, bolt(
    "bolt of acid", 4, 13, 3, 5, "MR_RES_ACID", bolts.corrode))

projectile.register(spells.SPELL_QUICKSILVER_BOLT, bolt(
    "bolt of dispelling energy", 6, 15, 2, 3, nil, bolts.dispel))

return bolts
