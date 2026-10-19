-- The electric orb bursts with radius two; contact damage and electrical
-- resistance use the ordinary beam explosion owner.
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local effect = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_ORB_OF_ELECTRICITY)

-- Plan a safe endpoint before committing an electrical explosion.
function effect.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Damage every actor in the source radius after endpoint tracing.
function effect.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return effect
