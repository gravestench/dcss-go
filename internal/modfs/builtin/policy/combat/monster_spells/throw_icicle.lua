local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local throw_icicle = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_THROW_ICICLE)

function throw_icicle.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function throw_icicle.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return throw_icicle
