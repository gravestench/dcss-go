local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.sentinel_mark")
local spells = require("ids.spells")

local mark = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_SENTINEL_MARK)

function mark.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

function mark.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return mark
