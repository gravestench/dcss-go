local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local iron_shot = {}
-- Iron Shot is a single-target physical projectile; shared beam contact handles its hit roll.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_IRON_SHOT)

-- Example: iron_shot.plan(ctx, caster, foe) with clear path -> entity plan for a physical hit
-- Targets one actor for the shared physical hit roll.
function iron_shot.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- One physical contact uses the shared hit roll and armour rule.
function iron_shot.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return iron_shot
