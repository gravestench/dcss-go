local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local poison = require("policy.combat.monster_beams.poison")
local spells = require("ids.spells")

local spit_poison = {}
-- Spit Poison follows the beam trace and applies poison through the shared contact rule.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_SPIT_POISON)

-- Example: spit_poison.plan(ctx, caster, foe) with clear ray -> entity plan for later poison trace
-- Saves an aim only when the poison ray reaches the foe without hitting allies.
function spit_poison.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- The shared contact rule poisons only actors struck along the newly traced ray.
function spit_poison.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, poison)
end

return spit_poison
