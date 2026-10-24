-- Sting uses the registered poison-arrow zap; shared beam contact owns
-- damage, poison exposure, resistances, and attribution for both monsters
-- and Vehumet's god avatar.
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local sting = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_STING)

-- Plan a short, nonpiercing ray before the caster commits its action.
function sting.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Let the shared poison-arrow contact rules resolve each hit.
function sting.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return sting
