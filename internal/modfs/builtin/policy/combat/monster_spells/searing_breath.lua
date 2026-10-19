-- Xtahua's searing breath gets three-halves ordinary monster power in the
-- source. The shared ray still owns path, contact, and fire resistance.
local beam = require("policy.combat.monster_beams")
local beam_power = require("policy.combat.monster_beams.power")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local searing_breath = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_SEARING_BREATH)
local xtahua_profile = beam_power.with_multiplier(profile, 3, 2)

-- Read the live caster kind, while leaving the catalogued beam immutable.
function searing_breath.profile_for(ctx, caster)
    local actor = ctx:get(caster, component.ACTOR)

    if not actor then
        error("searing-breath caster has no actor")
    end

    if actor.kind_id == monsters.MONS_XTAHUA then
        return xtahua_profile
    end

    return profile
end

-- Reject unsafe or out-of-range aims before committing Xtahua's breath.
function searing_breath.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe,
        searing_breath.profile_for(ctx, caster))
end

-- Resolve every ray contact using the same boosted profile chosen at plan.
function searing_breath.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe,
        searing_breath.profile_for(ctx, caster), plan)
end

return searing_breath
