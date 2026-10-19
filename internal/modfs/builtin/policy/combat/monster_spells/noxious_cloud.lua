local area = require("policy.clouds.area")
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local cloud_sizes = require("constants.cloud_sizes")
local clouds = require("ids.clouds")
local poison = require("policy.combat.monster_beams.poison")
local spells = require("ids.spells")

local noxious_cloud = {}
-- Noxious Cloud poisons on contact, then places mephitic cloud cells at the endpoint.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_NOXIOUS_CLOUD)

-- Example: noxious_cloud.plan(ctx, caster, foe) with reachable foe -> cell plan for later mephitic-cloud placement
-- Rejects an aim if the later mephitic spread could reach an ally.
function noxious_cloud.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile, {
        cloud_max_size = cloud_sizes.MAX_VARIABLE,
    })
end

-- Contact poisoning occurs before ordinary damage so the hit outcome controls eligibility.
function noxious_cloud.before_damage(ctx, caster, defender, _, outcome)
    poison.before_damage(ctx, caster, defender, profile, outcome)
end

-- Draw a variable mephitic cell count only after endpoint targeting succeeds.
function noxious_cloud.after_endpoint(ctx, caster, _, plan)
    local count = cloud_sizes.MIN_VARIABLE +
        ctx:random("monster_spell", cloud_sizes.MAX_VARIABLE -
            cloud_sizes.MIN_VARIABLE + 1)

    area.place(ctx, clouds.CLOUD_MEPHITIC, caster,
        plan.level_id, plan.x, plan.y, 0, count,
        "monster_spell")
end

-- Apply contact poison before placing mephitic clouds at the saved endpoint.
function noxious_cloud.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, noxious_cloud)
end

return noxious_cloud
