local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local poison = require("policy.combat.monster_beams.poison")
local spells = require("ids.spells")

local poison_arrow = {}
-- Poison Arrow takes its poisoning behaviour from beam contact after the projectile hits.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_POISON_ARROW)

-- Example: poison_arrow.plan(ctx, caster, foe) with clear ray -> entity plan for poison-arrow contact
-- Uses beam contact to poison a landed target.
function poison_arrow.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- The poisoned contact runs only after the arrow lands on its saved target.
function poison_arrow.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, poison)
end

return poison_arrow
