local area = require("policy.clouds.area")
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local cloud_sizes = require("constants.cloud_sizes")
local clouds = require("ids.clouds")
local poison = require("policy.combat.monster_beams.poison")
local spells = require("ids.spells")

local poisonous_cloud = {}
-- Poisonous Cloud applies contact poison before placing its poison cloud at the endpoint.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_POISONOUS_CLOUD)

-- Example: poisonous_cloud.plan(ctx, caster, foe) with reachable foe -> cell plan for later poison-cloud placement
-- Rejects an aim if the later cloud spread could reach an ally.
function poisonous_cloud.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile, {
        cloud_max_size = cloud_sizes.MAX_VARIABLE,
    })
end

-- The shared poison hook uses hit outcome and profile for direct contact exposure.
function poisonous_cloud.before_damage(ctx, caster, defender, _, outcome)
    poison.before_damage(ctx, caster, defender, profile, outcome)
end

-- Power and cell count consume monster-spell RNG only when the endpoint exists.
function poisonous_cloud.after_endpoint(ctx, caster, _, plan)
    local power = cloud_sizes.VARIABLE_POWER_MIN +
        ctx:random("monster_spell", cloud_sizes.VARIABLE_POWER_MAX -
            cloud_sizes.VARIABLE_POWER_MIN + 1)
    local count = cloud_sizes.MIN_VARIABLE +
        ctx:random("monster_spell", cloud_sizes.MAX_VARIABLE -
            cloud_sizes.MIN_VARIABLE + 1)

    area.place(ctx, clouds.CLOUD_POISON, caster,
        plan.level_id, plan.x, plan.y, power, count,
        "monster_spell")
end

-- Contact poison precedes poison-cloud placement at the endpoint.
function poisonous_cloud.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, poisonous_cloud)
end

return poisonous_cloud
