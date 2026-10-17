local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local stone_arrow = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_STONE_ARROW)

function stone_arrow.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function stone_arrow.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return stone_arrow
