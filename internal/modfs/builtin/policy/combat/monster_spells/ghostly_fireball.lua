local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local draining = require("policy.combat.monster_beams.draining")
local spells = require("ids.spells")

local ghostly_fireball = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_GHOSTLY_FIREBALL)

function ghostly_fireball.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function ghostly_fireball.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, draining)
end

return ghostly_fireball
