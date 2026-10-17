local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local bolt_of_magma = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_BOLT_OF_MAGMA)

function bolt_of_magma.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function bolt_of_magma.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return bolt_of_magma
