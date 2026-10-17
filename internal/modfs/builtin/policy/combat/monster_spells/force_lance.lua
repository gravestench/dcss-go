local beam = require("policy.combat.monster_beams")
local beam_power = require("policy.combat.monster_beams.power")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local displacement = require("policy.combat.monster_beams.displacement")
local spells = require("ids.spells")

local force_lance = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_FORCE_LANCE)

function force_lance.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function force_lance.after_hit(ctx, caster, defender, _, outcome, incoming)
    local power = beam_power.caster_power(ctx, caster, profile)

    displacement.push(ctx, caster, defender, outcome.damage, power,
        incoming)
end

function force_lance.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, force_lance)
end

return force_lance
