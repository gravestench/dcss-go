local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local lehudibs_crystal_spear = {}
-- Crystal Spear uses the high-damage single-target profile through shared beam contact.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_LEHUDIBS_CRYSTAL_SPEAR)

-- Example: lehudibs_crystal_spear.plan(ctx, caster, foe) with in-range foe -> entity plan for a high-damage hit
-- Uses the spear's high-damage profile.
function lehudibs_crystal_spear.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- The spear profile supplies its high damage to one shared beam contact.
function lehudibs_crystal_spear.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return lehudibs_crystal_spear
