local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.banishment")
local spells = require("ids.spells")

local banishment = {}
-- Banishment keeps its player and monster displacement outcomes in the hex rule after resistance is checked.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_BANISHMENT)

-- Example: banishment.plan(ctx, caster, foe) with reachable foe -> entity plan for hex resolution
-- Checks reach before the hex rule chooses the displacement outcome.
function banishment.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

-- Shared hex resolution checks resistance before the banishment rule relocates the defender.
function banishment.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return banishment
