local area = require("policy.clouds.area")
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local cloud_sizes = require("constants.cloud_sizes")
local clouds = require("ids.clouds")
local component = require("constants.component")
local miasma = require("policy.clouds.effects.miasma")
local spells = require("ids.spells")

local miasma_breath = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_MIASMA_BREATH)

function miasma_breath.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile, {
        cloud_max_size = cloud_sizes.FIXED_LARGE,
    })
end

function miasma_breath.before_damage(ctx, caster, defender, _, outcome)
    if ctx:has(defender, component.PLAYER) and outcome.damage <= 0 then
        return
    end

    miasma.afflict(ctx, defender, caster, "monster_spell", false)
end

-- beam.cc:bolt::get_cloud_type/get_cloud_size leaves ten miasma cells.
function miasma_breath.after_endpoint(ctx, caster, _, _, endpoint)
    area.place(ctx, clouds.CLOUD_MIASMA, caster,
        endpoint.level_id, endpoint.x, endpoint.y,
        cloud_sizes.BASE_POWER, cloud_sizes.FIXED_LARGE,
        "monster_spell")
end

function miasma_breath.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan,
        miasma_breath)
end

return miasma_breath
