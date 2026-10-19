local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.agony")
local spells = require("ids.spells")

local agony = {}
local profile = catalog.get(categories.MONSTER_BEAMS, spells.SPELL_AGONY)

function agony.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

function agony.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return agony
