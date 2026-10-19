local acid = require("policy.combat.monster_beams.acid")
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local spit_acid = {}
-- Spit Acid shares projectile tracing with monster beams, including acid contact effects.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_SPIT_ACID)

-- Example: spit_acid.plan(ctx, caster, foe) with clear ray -> entity plan for later acid trace
-- Saves an aim only when the acid ray can reach the foe without hitting allies.
function spit_acid.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Beam contact handles acid damage and corrosion on each landed hit.
function spit_acid.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, acid)
end

return spit_acid
