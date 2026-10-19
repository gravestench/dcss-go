local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.dimension_anchor")
local spells = require("ids.spells")

local anchor = {}
-- Dimension Anchor removes a pending player teleport when its hex rule succeeds.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_DIMENSION_ANCHOR)

-- Example: anchor.plan(ctx, caster, foe) with valid foe -> entity plan for the teleport-blocking hex
-- Can clear an existing player teleport after the hex succeeds.
function anchor.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

-- The hex rule removes a pending teleport only after the anchor lands.
function anchor.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return anchor
