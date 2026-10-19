local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.strip_willpower")
local spells = require("ids.spells")

local strip = {}
-- Strip Willpower can bypass resistance on one roll; its hex rule stores the lowered-will duration.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_STRIP_WILLPOWER)

-- Example: strip.plan(ctx, caster, foe) with foe already lowered in will -> nil plan
-- Precedes the one-roll resistance bypass and lowered will.
function strip.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

-- The hex rule handles its special resistance roll before extending lowered will.
function strip.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return strip
