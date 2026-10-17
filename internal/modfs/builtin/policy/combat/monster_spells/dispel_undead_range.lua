local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local dispel_undead_range = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_DISPEL_UNDEAD_RANGE)

function dispel_undead_range.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function dispel_undead_range.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return dispel_undead_range
