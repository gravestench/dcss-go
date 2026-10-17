local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local pies = require("policy.combat.monster_beams.pies")
local spells = require("ids.spells")

local throw_pie = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_THROW_PIE)

function throw_pie.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function throw_pie.after_hit(ctx, caster, defender, _, outcome)
    pies.apply(ctx, caster, defender, outcome)
end

function throw_pie.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, throw_pie)
end

return throw_pie
