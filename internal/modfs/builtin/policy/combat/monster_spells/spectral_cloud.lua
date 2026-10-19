-- Spectral Cloud's harmless ray leaves 5–10 turn mist along its path and
-- a broader field at the endpoint. The cloud owner handles damage and
-- spectral summons later, preserving both through saves.
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

local spectral_cloud = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_SPECTRAL_CLOUD)

local TRAIL_BASE_TURNS = 5
local TRAIL_RANDOM_TURNS = 6
local FIELD_BASE_POWER = 12
local FIELD_RANDOM_POWER = 9

-- The broad possible field determines ally safety even though the ray
-- itself deals no immediate damage.
function spectral_cloud.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile, {
        cloud_max_size = cloud_sizes.MAX_VARIABLE,
    })
end

-- Source beam.cc chooses 12–20 endpoint power and 8–12 cloud cells after
-- placing the individual ray-cell mists.
function spectral_cloud.after_endpoint(ctx, caster, _, _, endpoint)
    trail.place(ctx, caster, clouds.CLOUD_SPECTRAL, endpoint,
        TRAIL_BASE_TURNS, TRAIL_RANDOM_TURNS)

    local power = FIELD_BASE_POWER +
        ctx:random(streams.MONSTER_SPELL, FIELD_RANDOM_POWER)
    local count = cloud_sizes.MIN_VARIABLE +
        ctx:random(streams.MONSTER_SPELL, cloud_sizes.MAX_VARIABLE -
            cloud_sizes.MIN_VARIABLE + 1)

    area.place(ctx, clouds.CLOUD_SPECTRAL, caster,
        endpoint.level_id, endpoint.x, endpoint.y,
        power, count, streams.MONSTER_SPELL)
end

-- Pass the saved ray through the common contact and endpoint owners.
function spectral_cloud.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan,
        spectral_cloud)
end

return spectral_cloud
