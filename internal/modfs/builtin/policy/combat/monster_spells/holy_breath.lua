local beam = require("policy.combat.monster_beams")
local area = require("policy.clouds.area")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local cloud_sizes = require("constants.cloud_sizes")
local clouds = require("ids.clouds")
local spells = require("ids.spells")

local holy_breath = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_HOLY_BREATH)

function holy_breath.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- beam.cc:bolt::get_cloud_type/get_cloud_size puts a variable holy
-- cloud at the breath's endpoint after the damaging ray.
function holy_breath.after_endpoint(ctx, caster, _, _, endpoint)
    local spread = cloud_sizes.MAX_VARIABLE -
        cloud_sizes.MIN_VARIABLE + 1
    local count = cloud_sizes.MIN_VARIABLE +
        ctx:random("monster_spell", spread)

    area.place(ctx, clouds.CLOUD_HOLY, caster,
        endpoint.level_id, endpoint.x, endpoint.y,
        cloud_sizes.BASE_POWER, count, "monster_spell")
end

function holy_breath.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, holy_breath)
end

return holy_breath
