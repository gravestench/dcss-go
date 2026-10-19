-- Source mon-cast.cc weakens a draconian's cold ray before the shared beam
-- rules calculate damage. Tiamat has draconian genus but is outside the
-- source mons_is_draconian range, so her power is not reduced.
local beam = require("policy.combat.monster_beams")
local beam_power = require("policy.combat.monster_beams.power")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local cold_breath = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_COLD_BREATH)
local draconian_profile = beam_power.with_multiplier(profile, 2, 3)

-- Return the immutable profile for this caster. The source two-thirds
-- multiplier follows even an overlaid base power factor.
function cold_breath.profile_for(ctx, caster)
    local actor = ctx:get(caster, component.ACTOR)

    if not actor then
        error("cold-breath caster has no actor")
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    if definition.genus_id == monsters.MONS_DRACONIAN and
        actor.kind_id ~= monsters.MONS_TIAMAT then
        return draconian_profile
    end

    return profile
end

-- Plan with the same caster-specific power profile used at resolution.
function cold_breath.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe,
        cold_breath.profile_for(ctx, caster))
end

-- The shared ray applies cold resistance independently at every contact.
function cold_breath.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe,
        cold_breath.profile_for(ctx, caster), plan)
end

return cold_breath
