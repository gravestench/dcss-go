local component = require("constants.component")
local streams = require("constants.rng_streams")
local ids = require("ids.clouds")
local placement = require("policy.clouds.placement")
local content = require("policy.catalog")
local categories = require("constants.catalog")
local neighbors = require("constants.adjacent_cells")

local field = {}

local function source_actor(ctx, state)
    if not state.source_actor_id or state.source_actor_id == 0 then
        return nil
    end

    return ctx:entity(state.source_actor_id)
end

local function spread_chance(decay_aut)
    if decay_aut > 30 then
        return 80
    end

    if decay_aut > 20 then
        return 50
    end

    return 30
end

local function spread(ctx, state)
    local chance = spread_chance(state.decay_aut)
    local extra_decay = 0
    local source = source_actor(ctx, state)

    for _, offset in ipairs(neighbors) do
        if ctx:random(streams.CLOUDS, 100) < chance then
            local x = state.x + offset[1]
            local y = state.y + offset[2]
            local decay = math.floor(state.decay_aut / 2) + 1

            if decay >= state.decay_aut then
                decay = state.decay_aut - 1
            end

            if decay > 0 and
                not placement.at(ctx, state.level_id, x, y) then
                local placed = placement.place(ctx, state.kind_id, source,
                    state.level_id, x, y, decay, {
                        source_actor_id = state.source_actor_id,
                        kill_category = state.kill_category,
                        killer_type = state.killer_type,
                        spread_rate = state.spread_rate,
                        exclusion_radius = state.exclusion_radius,
                        special_ints = state.special_ints,
                    })

                if placed then
                    extra_decay = extra_decay + 8
                end
            end
        end
    end

    return extra_decay
end

local function lower_spread_rate(ctx, rate)
    local reduction = math.floor(rate / 10)
    local remainder = rate % 10

    if remainder > 0 and
        ctx:random(streams.CLOUDS, 10) < remainder then
        reduction = reduction + 1
    end

    return math.max(0, rate - reduction)
end

local function dissipate(ctx, entity, state, elapsed_aut)
    local definition = content.get(categories.CLOUDS, state.kind_id)
    local effect = require(definition.effect)

    if effect.before_age then
        effect.before_age(ctx, state, elapsed_aut)
    end

    if not state.opaque and state.source_actor_id and
        state.source_actor_id > 0 and
        state.source_actor_id == ctx:id(ctx:player()) then
        local player = ctx:player()
        local position = ctx:get(player, component.POSITION)

        if position and (
            position.level_id ~= state.level_id or
            not ctx:visible(state.level_id,
                position.x, position.y, 7, state.x, state.y)) then
            state.decay_aut = 0
        end
    end

    if state.kind_id == ids.CLOUD_INK then
        local terrain = require("content.terrain_features")
        local feature = ctx:cell(state.level_id, state.x, state.y)

        if feature ~= terrain.vault_terrain.DNGN_SHALLOW_WATER and
            feature ~= terrain.vault_terrain.DNGN_DEEP_WATER then
            state.decay_aut = 0
        end
    end

    state.decay_aut = state.decay_aut - elapsed_aut

    if state.spread_rate > 0 and
        ctx:random(streams.CLOUDS, 100) < state.spread_rate then
        state.spread_rate = lower_spread_rate(ctx, state.spread_rate)
        state.decay_aut = state.decay_aut - spread(ctx, state)
    end

    if state.decay_aut < 1 then
        if effect.expire and effect.expire(ctx, entity, state) then
            return
        end

        placement.remove(ctx, entity)

        return
    end

    ctx:set(entity, component.WORLD_CLOUD, state)
end

function field.advance(ctx, input)
    if input.elapsed_aut < 1 then
        return {}
    end

    -- Snapshot before spreading; children start aging on the next action.
    local active = {}

    for _, entity in ipairs(ctx:query({ component.WORLD_CLOUD })) do
        local state = ctx:get(entity, component.WORLD_CLOUD)

        if state and state.level_id == input.level_id then
            active[#active + 1] = entity
        end
    end

    for _, entity in ipairs(active) do
        local state = ctx:get(entity, component.WORLD_CLOUD)

        if state then
            dissipate(ctx, entity, state, input.elapsed_aut)
        end
    end

    return {}
end

register.policy({
    id = "world.cloud_field",
    run = field.advance,
})

return field
