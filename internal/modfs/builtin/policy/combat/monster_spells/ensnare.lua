-- Source Ensnare fires a physical webbing projectile. The beam owner handles
-- walls, shields, evasion, and misses; the common web owner handles hold,
-- floor trap placement, escape, and persistence after a landed hit.
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local ensnare_web = require("policy.combat.monster_area.web")
local spells = require("ids.spells")

local effect = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_ENSNARE)

-- Preserve the chosen foe and projectile direction across the intent
-- boundary. An obstruction before the foe makes this cast ineligible.
function effect.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- A web is applied only after the ordinary beam has reached and hit its
-- contact actor; immunity and existing holds are checked by the web owner.
function effect.after_hit(ctx, caster, defender)
    return ensnare_web.after_hit(ctx, caster, defender)
end

-- Webbing has no HP flavour. Skipping damage also avoids asking the generic
-- beam damage policy to invent a resistance rule for BEAM_ENSNARE.
function effect.skip_damage()
    return true
end

-- The source beam deals zero HP damage. Its landed contact still calls
-- after_hit and records a restraint through the shared trap policy.
function effect.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, effect)
end

return effect
