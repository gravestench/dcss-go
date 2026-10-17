-- cloud.cc:CLOUD_SPECTRAL deals non-elemental damage; field aging may
-- create a spectral thing when its source remains alive.
local categories = require("constants.catalog")
local elemental = require("policy.clouds.effects.elemental")
local component = require("constants.component")
local catalog = require("policy.catalog")
local holiness = require("constants.monster_holiness")
local streams = require("constants.rng_streams")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local attribution = require("constants.cloud_attribution")
local pool = require("policy.population.pool")
local summons = require("policy.magic.effects.summons.common")

local spectral = {}

function spectral.immune(ctx, actor)
    if actor == ctx:player() then
        return false
    end

    local state = ctx:get(actor, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, state.kind_id)

    for _, kind in ipairs(definition.holiness or {}) do
        if kind == holiness.UNDEAD then
            return true
        end
    end

    return false
end

function spectral.apply(ctx, actor, state, elapsed_aut, _, definition)
    return elemental.apply(ctx, actor, state, elapsed_aut,
        definition, nil, {
            immune = spectral.immune,
        })
end

local emission_rate = { 650, 175, 45, 20, 0 }

local fixed_bases = {
    { id = monsters.MONS_ANACONDA, weight = 4 },
    { id = monsters.MONS_HYDRA, weight = 6 },
    { id = monsters.MONS_SNAPPING_TURTLE, weight = 3 },
    { id = monsters.MONS_ALLIGATOR_SNAPPING_TURTLE, weight = 2 },
}

local function nearby_spectral(ctx, state)
    local count = 0

    for _, entity in ipairs(ctx:query({
        component.ACTOR, component.POSITION,
    })) do
        local actor = ctx:get(entity, component.ACTOR)
        local position = ctx:get(entity, component.POSITION)

        if actor.kind_id == monsters.MONS_SPECTRAL_THING and
            position.level_id == state.level_id and
            math.max(math.abs(position.x - state.x),
                math.abs(position.y - state.y)) <= 2 then
            count = count + 1
        end
    end

    return math.min(4, count)
end

local function base_kind(ctx, state)
    local draw = ctx:random(streams.CLOUDS, 115)

    for _, choice in ipairs(fixed_bases) do
        if draw < choice.weight then
            return choice.id
        end

        draw = draw - choice.weight
    end

    local choices, total = pool.at_depth(state.level_id)

    if total == 0 then
        return monsters.MONS_RAT
    end

    return pool.pick(ctx, choices, total, streams.CLOUDS)
end

function spectral.before_age(ctx, state, elapsed_aut)
    if ctx:actor_at(state.level_id, state.x, state.y) or
        state.source_actor_id < 1 then
        return
    end

    local source = ctx:entity(state.source_actor_id)

    if not source then
        return
    end

    local chance = emission_rate[nearby_spectral(ctx, state) + 1]

    if chance == 0 or
        ctx:random(streams.CLOUDS, elapsed_aut * 600) >= chance then
        return
    end

    local base = catalog.get(categories.MONSTERS, base_kind(ctx, state))
    local anchor = {
        level_id = state.level_id,
        x = state.x,
        y = state.y,
    }
    local spawned = summons.spawn(ctx, source,
        spells.SPELL_SPECTRAL_CLOUD,
        monsters.MONS_SPECTRAL_THING, 1, 999, {
            anchor = anchor,
            exact = {
                x = state.x,
                y = state.y,
            },
            hostile = state.kill_category == attribution.OTHER,
            hp = math.max(1, math.floor(base.average_hp_10x / 10)),
            hd = math.max(1, base.hd),
        })

    if spawned then
        ctx:add(spawned, component.SUMMON_UNDEAD, {
            base_kind_id = base.id,
        })
    end
end

return spectral
