local spells = require("ids.spells")
local enchant = require("policy.combat.monster_enchant")
local projectile = require("policy.magic.effects.zaps.projectile")

local bolts = {}

-- Example: An acid bolt contact adds corrosion through the shared monster enchant rule.
-- Delegate blindness to the shared enchant rule after projectile contact has selected a monster.
function bolts.blind(ctx, _, target, definition)
    enchant.blind(ctx, target, definition)
end

-- Apply corrosion only after the bolt has hit a monster; the enchant policy owns stacking.
function bolts.corrode(ctx, _, target, definition)
    enchant.corrode(ctx, target, definition)
end

-- Dispel target enchantments at contact while the beam policy owns trajectory.
function bolts.dispel(ctx, _, target, definition)
    enchant.dispel(ctx, target, definition)
end

-- Build a shared bolt profile so each elemental spell uses the same dice and beam rules.
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
