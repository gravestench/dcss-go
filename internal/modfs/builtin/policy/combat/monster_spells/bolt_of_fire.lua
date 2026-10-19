local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local bolt_of_fire = {}
-- The fire bolt uses a penetrating beam profile so every actor on the trace may be hit.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_BOLT_OF_FIRE)

-- Example: bolt_of_fire.plan(ctx, caster, foe) with foe behind an actor -> entity plan for later piercing fire trace
-- Saves a foe-directed aim; the piercing profile lets resolution trace through earlier actors.
function bolt_of_fire.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Resolution walks the complete fire ray, including actors behind the first hit.
function bolt_of_fire.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return bolt_of_fire
