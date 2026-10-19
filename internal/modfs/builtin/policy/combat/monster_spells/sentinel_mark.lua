local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.sentinel_mark")
local spells = require("ids.spells")

local mark = {}
-- Sentinel Mark targets only the player; its rule writes the mark after the shared hex check.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_SENTINEL_MARK)

-- Example: mark.plan(ctx, caster, foe) with nonplayer foe -> nil plan
-- Accepts only the player before writing the mark.
function mark.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

-- The rule marks the player only after the shared hex contest succeeds.
function mark.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return mark
