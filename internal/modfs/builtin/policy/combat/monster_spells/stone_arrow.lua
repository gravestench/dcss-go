local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local stone_arrow = {}
-- Stone Arrow uses the physical projectile profile with ordinary beam hit and armour handling.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_STONE_ARROW)

-- Example: stone_arrow.plan(ctx, caster, foe) with clear ray -> entity plan for a physical hit
-- Targets one actor for physical armour handling.
function stone_arrow.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- The planned single-target projectile uses ordinary physical armour handling.
function stone_arrow.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return stone_arrow
