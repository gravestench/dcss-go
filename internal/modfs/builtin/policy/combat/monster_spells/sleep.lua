local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local sleep_rule = require("policy.combat.monster_beams.sleep")
local spells = require("ids.spells")

local sleep = {}
-- Sleep is resolved by beam contact so the catalogued enchantment profile governs resistance.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_SLEEP)

-- Example: sleep.plan(ctx, caster, foe) with viable foe -> entity plan for sleep enchantment
-- Uses enchantment power for contact resistance.
function sleep.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Beam contact applies the profile's enchantment resistance before sleep state.
function sleep.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, sleep_rule)
end

return sleep
