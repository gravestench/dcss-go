local acid = require("policy.combat.monster_beams.acid")
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local corrosive_bolt = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_CORROSIVE_BOLT)

function corrosive_bolt.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function corrosive_bolt.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, acid)
end

return corrosive_bolt
