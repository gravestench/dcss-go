local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local energy_bolt = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_ENERGY_BOLT)

function energy_bolt.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function energy_bolt.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return energy_bolt
