local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local poison = require("policy.combat.monster_beams.poison")
local spells = require("ids.spells")

local poison_arrow = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_POISON_ARROW)

function poison_arrow.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function poison_arrow.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, poison)
end

return poison_arrow
