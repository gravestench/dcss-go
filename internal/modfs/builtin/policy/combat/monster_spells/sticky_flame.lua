-- The adjacent Sticky Flame zap shares its target status owner with the
-- ranged variant; only its source hit profile differs.
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")
local sticky = require("policy.combat.monster_spells.sticky_flame_range")

local effect = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_STICKY_FLAME)

-- A sticky hit uses a single target ray with source automatic accuracy.
function effect.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- The shared hook writes ongoing flame on the contacted actor.
function effect.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, sticky)
end

return effect
