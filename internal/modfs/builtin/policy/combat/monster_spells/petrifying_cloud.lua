-- The ray's immediate damage is physical; calcifying dust on traversed
-- cells applies the later petrification through the cloud exposure system.
-- Source: mon-cast.cc, beam.cc:affect_place_clouds.
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local clouds = require("ids.clouds")
local spells = require("ids.spells")
local trail = require("policy.combat.monster_beams.trail")

local petrifying_cloud = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_PETRIFYING_CLOUD)

local TRAIL_BASE_TURNS = 4
local TRAIL_RANDOM_TURNS = 4

-- This source spell is a directional ray, not a centered area spell, so
-- its target plan names the foe and excludes allied ray contacts.
function petrifying_cloud.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Each travelled cell receives 4–7 turns of calcifying dust; no separate
-- endpoint burst appears in the source for this spell.
function petrifying_cloud.after_endpoint(ctx, caster, _, _, endpoint)
    trail.place(ctx, caster, clouds.CLOUD_PETRIFY, endpoint,
        TRAIL_BASE_TURNS, TRAIL_RANDOM_TURNS)
end

-- Keep the saved trajectory and contact order, then place its dust trail.
function petrifying_cloud.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan,
        petrifying_cloud)
end

return petrifying_cloud
