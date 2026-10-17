local acid = require("policy.combat.monster_beams.acid")
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local spit_acid = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_SPIT_ACID)

function spit_acid.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function spit_acid.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, acid)
end

return spit_acid
