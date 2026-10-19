local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local throw_frost = {}
-- Throw Frost uses the short cold projectile profile and shared beam contact.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_THROW_FROST)

-- Example: throw_frost.plan(ctx, caster, foe) with foe inside short range -> entity plan for a short-range cold hit
-- Limits the cold projectile to its short profile range.
function throw_frost.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- The short cold profile resolves at each contact on the newly traced ray.
function throw_frost.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return throw_frost
