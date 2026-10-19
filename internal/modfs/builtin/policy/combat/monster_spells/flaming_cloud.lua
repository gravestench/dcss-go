-- Flaming Cloud is a natural fire breath whose ray burns on contact and
-- leaves both a short-lived fire trail and a broad field at the endpoint.
-- Source: mon-cast.cc, beam.cc:get_cloud_type/affect_place_clouds.
local area = require("policy.clouds.area")
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local cloud_sizes = require("constants.cloud_sizes")
local clouds = require("ids.clouds")
local streams = require("constants.rng_streams")
local spells = require("ids.spells")
local trail = require("policy.combat.monster_beams.trail")

local flaming_cloud = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_FLAMING_CLOUD)

local TRAIL_BASE_TURNS = 2
local TRAIL_RANDOM_TURNS = 4

-- Keep the possible twelve-cell fire field clear of the caster's allies
-- before it commits the breath action.
function flaming_cloud.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile, {
        cloud_max_size = cloud_sizes.MAX_VARIABLE,
    })
end

-- Source beam.cc leaves 2–5 turns of fire on each ray cell, then draws an
-- 8–12 cell endpoint cloud. Both use ordinary saved cloud entities.
function flaming_cloud.after_endpoint(ctx, caster, _, _, endpoint)
    trail.place(ctx, caster, clouds.CLOUD_FIRE, endpoint,
        TRAIL_BASE_TURNS, TRAIL_RANDOM_TURNS)

    local count = cloud_sizes.MIN_VARIABLE +
        ctx:random(streams.MONSTER_SPELL, cloud_sizes.MAX_VARIABLE -
            cloud_sizes.MIN_VARIABLE + 1)

    area.place(ctx, clouds.CLOUD_FIRE, caster,
        endpoint.level_id, endpoint.x, endpoint.y,
        cloud_sizes.BASE_POWER, count, streams.MONSTER_SPELL)
end

-- Resolve the chosen ray before placing its persistent fire field.
function flaming_cloud.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan,
        flaming_cloud)
end

return flaming_cloud
