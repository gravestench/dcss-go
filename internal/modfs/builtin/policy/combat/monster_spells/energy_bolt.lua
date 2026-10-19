local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local energy_bolt = {}
-- The devastation-flavoured Energy Bolt follows beam targeting with its catalogued damage dice.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_ENERGY_BOLT)

-- Example: energy_bolt.plan(ctx, caster, foe) with in-range foe -> entity plan for devastation damage
-- Uses the devastation profile's damage dice.
function energy_bolt.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- The saved beam resolves with the devastation profile's catalogued damage.
function energy_bolt.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return energy_bolt
