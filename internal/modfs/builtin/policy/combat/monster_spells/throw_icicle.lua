local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local throw_icicle = {}
-- Throw Icicle resolves its cold projectile through beam contact with the catalogued dice.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_THROW_ICICLE)

-- Example: throw_icicle.plan(ctx, caster, foe) with clear ray -> entity plan for a cold projectile hit
-- Uses catalog dice for the cold projectile.
function throw_icicle.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- The cold projectile uses catalog dice at the contact traced during resolution.
function throw_icicle.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return throw_icicle
