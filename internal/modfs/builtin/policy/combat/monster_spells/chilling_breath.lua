-- Chilling Breath is a natural cold ray. Its shorter source cap and frost
-- damage formula belong to its profile, not a second trajectory policy.
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local chilling_breath = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_CHILLING_BREATH)

-- Plan a safe penetration path before spending the breath action.
function chilling_breath.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Apply the source frost zap through ordinary beam contact and resistance.
function chilling_breath.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return chilling_breath
