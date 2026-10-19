local acid = require("policy.combat.monster_beams.acid")
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local corrosive_bolt = {}
-- Corrosive Bolt uses beam contact to apply acid damage and any resulting corrosion.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_CORROSIVE_BOLT)

-- Example: corrosive_bolt.plan(ctx, caster, foe) with clear ray -> entity plan for acid contact
-- Routes acid hits through contact corrosion.
function corrosive_bolt.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Acid contact applies corrosion only to defenders actually struck by the ray.
function corrosive_bolt.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, acid)
end

return corrosive_bolt
