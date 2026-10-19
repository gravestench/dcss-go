local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.pain")
local spells = require("ids.spells")

local pain = {}
-- Pain leaves negative-energy resistance and damage calculation to its hex rule.
local profile = catalog.get(categories.MONSTER_BEAMS, spells.SPELL_PAIN)

-- Example: pain.plan(ctx, caster, foe) with torment-immune foe -> nil plan
-- Defers negative-energy resistance to the hex rule.
function pain.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

-- The hex rule computes negative-energy damage after its resistance check.
function pain.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return pain
