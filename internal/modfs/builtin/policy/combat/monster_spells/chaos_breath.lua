local area = require("policy.clouds.area")
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local cloud_sizes = require("constants.cloud_sizes")
local clouds = require("ids.clouds")
local impact = require("policy.combat.monster_area.chaos_impact")
local pool = require("policy.combat.monster_area.chaos_flavours")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")

local breath = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_CHAOS_BREATH)

-- The source cloud tracer reserves every possible 8..12-cell spread.
function breath.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile, {
        cloud_max_size = cloud_sizes.MAX_VARIABLE,
    })
end

-- Each contacted actor draws a chaos flavour before damage and resistance.
-- The shared ray owner still resolves shield stops and reflections.
function breath.contact(ctx, caster, defender, source_profile,
    power, to_hit, flavour)
    return impact.contact(ctx, caster, defender, power,
        to_hit, source_profile, flavour)
end

-- beam.cc seeds zero-power chaos clouds at the stopped beam endpoint.
function breath.after_endpoint(ctx, caster, _, _, endpoint)
    local count = cloud_sizes.MIN_VARIABLE +
        ctx:random(streams.MONSTER_SPELL,
            cloud_sizes.MAX_VARIABLE - cloud_sizes.MIN_VARIABLE + 1)

    area.place(ctx, clouds.CLOUD_CHAOS, caster,
        endpoint.level_id, endpoint.x, endpoint.y,
        cloud_sizes.BASE_POWER, count, streams.MONSTER_SPELL)
end

function breath.resolve(ctx, caster, foe, _, plan)
    local selected
    local hook = {
        after_endpoint = breath.after_endpoint,
    }

    function hook.cell(context)
        selected = pool.choose(context, streams.MONSTER_SPELL)
    end

    function hook.contact(context, source, defender, source_profile,
        power, to_hit)
        return breath.contact(context, source, defender,
            source_profile, power, to_hit, selected)
    end

    return beam.resolve(ctx, caster, foe, profile, plan, hook)
end

return breath
