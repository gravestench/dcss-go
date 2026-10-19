local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.pain")
local spells = require("ids.spells")

local pain = {}
local profile = catalog.get(categories.MONSTER_BEAMS, spells.SPELL_PAIN)

function pain.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

function pain.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return pain
