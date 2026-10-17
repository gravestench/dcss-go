local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local poison = require("policy.combat.monster_beams.poison")
local spells = require("ids.spells")

local spit_poison = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_SPIT_POISON)

function spit_poison.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function spit_poison.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, poison)
end

return spit_poison
