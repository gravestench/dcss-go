-- A frostbound tome's living spell uses the ordinary monster Iceblast
-- explosion path. Source: mon-cast.cc and zap-data.h:ZAP_ICEBLAST.
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local effect = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_ICEBLAST)

-- Plan a radius-one cold explosion without sacrificing a simulacrum.
function effect.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Trace the planned shot, then apply cold contact to the affected cells.
function effect.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return effect
