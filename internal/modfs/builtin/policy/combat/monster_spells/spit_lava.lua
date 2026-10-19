local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local spit_lava = {}
-- Spit Lava uses its catalogued fire beam profile for tracing and contact.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_SPIT_LAVA)

-- Example: spit_lava.plan(ctx, caster, foe) with clear ray -> entity plan for later fire trace
-- Uses the catalogued fire ray.
function spit_lava.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- The fire-flavoured profile resolves on the ray traced from the saved aim.
function spit_lava.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return spit_lava
