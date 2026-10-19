local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local thorn_volley = {}
-- Thorn Volley uses a single-target missile profile with the shared beam hit calculation.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_THORN_VOLLEY)

-- Example: thorn_volley.plan(ctx, caster, foe) with clear path -> entity plan for a missile-style hit
-- Uses a single-target missile profile.
function thorn_volley.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- The saved single-target missile uses the shared hit calculation.
function thorn_volley.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return thorn_volley
