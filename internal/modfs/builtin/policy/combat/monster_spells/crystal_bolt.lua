local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local crystal_bolt = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_CRYSTAL_BOLT)

function crystal_bolt.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function crystal_bolt.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return crystal_bolt
