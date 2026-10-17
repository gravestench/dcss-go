local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local lightning_bolt = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_LIGHTNING_BOLT)

function lightning_bolt.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function lightning_bolt.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return lightning_bolt
