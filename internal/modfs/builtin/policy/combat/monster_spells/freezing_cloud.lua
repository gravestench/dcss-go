local area = require("policy.clouds.area")
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local cloud_sizes = require("constants.cloud_sizes")
local clouds = require("ids.clouds")
local spells = require("ids.spells")

local freezing_cloud = {}
-- Freezing Cloud places cold cloud cells at the beam endpoint after trajectory resolution.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_FREEZING_CLOUD)

-- Example: freezing_cloud.plan(ctx, caster, foe) with reachable aim -> cell plan for later cold-cloud placement
-- Records the endpoint where cold cloud cells appear.
function freezing_cloud.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile, {
        cloud_max_size = cloud_sizes.FIXED_LARGE,
    })
end

-- Draw cloud power on the monster-spell stream only after the ray finds its endpoint.
function freezing_cloud.after_endpoint(ctx, caster, _, plan)
    local power = cloud_sizes.VARIABLE_POWER_MIN +
        ctx:random("monster_spell", cloud_sizes.VARIABLE_POWER_MAX -
            cloud_sizes.VARIABLE_POWER_MIN + 1)

    area.place(ctx, clouds.CLOUD_COLD, caster,
        plan.level_id, plan.x, plan.y, power,
        cloud_sizes.FIXED_LARGE, "monster_spell")
end

-- Place cold cloud cells at the planned endpoint after the beam trace resolves.
function freezing_cloud.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, freezing_cloud)
end

return freezing_cloud
