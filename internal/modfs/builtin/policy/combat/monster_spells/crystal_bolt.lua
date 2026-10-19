local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local crystal_bolt = {}
-- Crystal Bolt takes its physical damage dice from the catalog and reuses beam targeting.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_CRYSTAL_BOLT)

-- Example: crystal_bolt.plan(ctx, caster, foe) with clear path -> entity plan for physical contact
-- Uses catalog dice for a physical projectile.
function crystal_bolt.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- The physical projectile reuses shared hit and armour handling at the planned target.
function crystal_bolt.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return crystal_bolt
