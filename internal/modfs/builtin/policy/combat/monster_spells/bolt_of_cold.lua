local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local bolt_of_cold = {}
-- The cold bolt profile is piercing; beam resolution visits each contact along its traced path.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_BOLT_OF_COLD)

-- Example: bolt_of_cold.plan(ctx, caster, foe) with foe behind an actor -> entity plan for later piercing cold trace
-- Saves a foe-directed aim after checking the piercing cold ray is safe to cast.
function bolt_of_cold.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- The piercing cold ray applies contact damage to each actor traced at resolution.
function bolt_of_cold.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return bolt_of_cold
