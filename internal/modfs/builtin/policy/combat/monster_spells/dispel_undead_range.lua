local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local dispel_undead_range = {}
-- The ranged Dispel Undead profile reaches a target through beam contact, which checks undead eligibility.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_DISPEL_UNDEAD_RANGE)

-- Example: dispel_undead_range.plan(ctx, caster, foe) with undead foe in range -> entity plan for an undead contact
-- Checks a ranged undead target before contact.
function dispel_undead_range.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Contact checks undead eligibility before applying the ranged dispel damage.
function dispel_undead_range.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return dispel_undead_range
