local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local draining = require("policy.combat.monster_beams.draining")
local spells = require("ids.spells")

local bolt_of_draining = {}
-- This penetrating bolt leaves negative-energy resistance and drain handling to beam contact.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_BOLT_OF_DRAINING)

-- Example: bolt_of_draining.plan(ctx, caster, foe) with foe behind an actor
-- -> entity plan for later piercing drain trace
-- Saves the foe-directed aim; negative-energy and drain checks wait for resolution.
function bolt_of_draining.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Each contact traced at resolution receives negative-energy resistance and drain handling.
function bolt_of_draining.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, draining)
end

return bolt_of_draining
