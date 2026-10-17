local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local fireball = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_FIREBALL)

function fireball.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function fireball.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return fireball
