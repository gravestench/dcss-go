local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local lightning_bolt = {}
-- Lightning Bolt follows the electric beam profile, including bounce handling in the trajectory engine.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_LIGHTNING_BOLT)

-- Example: lightning_bolt.plan(ctx, caster, foe) with ray near wall -> entity plan; resolution later traces bounces
-- Saves the foe-directed aim after checking a bouncing ray can reach it safely.
function lightning_bolt.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- The newly traced electric ray may bounce; each contact resolves in order.
function lightning_bolt.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return lightning_bolt
