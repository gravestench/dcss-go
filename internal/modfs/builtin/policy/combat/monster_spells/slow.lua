local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.slow")
local spells = require("ids.spells")

local slow = {}
-- Slow applies distinct player and monster timing in its hex rule after resistance.
local profile = catalog.get(categories.MONSTER_BEAMS, spells.SPELL_SLOW)

-- Example: slow.plan(ctx, caster, foe) with viable foe -> entity plan for the slowing hex
-- Precedes player and monster status timing.
function slow.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

-- The hex rule keeps separate player and monster timing after resistance.
function slow.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return slow
