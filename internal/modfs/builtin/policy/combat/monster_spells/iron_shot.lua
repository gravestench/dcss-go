local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local iron_shot = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_IRON_SHOT)

function iron_shot.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function iron_shot.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return iron_shot
