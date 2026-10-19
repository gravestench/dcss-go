local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.dimension_anchor")
local spells = require("ids.spells")

local anchor = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_DIMENSION_ANCHOR)

function anchor.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

function anchor.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return anchor
