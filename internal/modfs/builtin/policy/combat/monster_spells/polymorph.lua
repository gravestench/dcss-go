local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.polymorph")
local spells = require("ids.spells")

local polymorph = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_POLYMORPH)

function polymorph.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

function polymorph.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return polymorph
