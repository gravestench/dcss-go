local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.paralyse")
local spells = require("ids.spells")

local paralyse = {}
-- Paralyse applies player paralysis as a status while its rule handles monster enchantment separately.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_PARALYSE)

-- Example: paralyse.plan(ctx, caster, foe) with viable foe -> entity plan for the paralysis hex
-- Precedes distinct player and monster paralysis state.
function paralyse.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

-- The rule writes player paralysis or monster enchantment according to target kind.
function paralyse.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return paralyse
