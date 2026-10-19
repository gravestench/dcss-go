local categories = require("constants.catalog")
local component = require("constants.component")
local attribution = require("constants.cloud_attribution")
local streams = require("constants.rng_streams")
local content = require("policy.catalog")
local ids = require("ids.clouds")
local selectors = require("constants.cloud_selectors")
local terrain = require("content.terrain_features")
local targets = require("policy.ai.targets")
local wind = require("policy.combat.monster_support.still_winds")

local placement = {}

local smoke = {
    ids.CLOUD_GREY_SMOKE,
    ids.CLOUD_BLUE_SMOKE,
    ids.CLOUD_BLACK_SMOKE,
    ids.CLOUD_PURPLE_SMOKE,
}

-- Ink placement is restricted to shallow or deep water.
local function is_water(feature)
    return feature == terrain.vault_terrain.DNGN_SHALLOW_WATER or
        feature == terrain.vault_terrain.DNGN_DEEP_WATER
end

-- All cloud kinds except ink use the general walkable-cell rule.
function placement.terrain_eligible(kind_id, feature)
    return kind_id ~= ids.CLOUD_INK or is_water(feature)
end

-- Resolve random smoke once; unresolved cloud selectors cannot become entities.
local function resolve_kind(ctx, kind_id)
    if kind_id == selectors.RANDOM_SMOKE then
        local index = ctx:random(streams.CLOUDS, #smoke) + 1

        return smoke[index]
    end

    if kind_id == selectors.NONE or
        kind_id == selectors.RANDOM or
        kind_id == selectors.DEBUGGING then
        error("cloud selector " .. kind_id .. " cannot be placed")
    end

    return kind_id
end

-- Replacement honours harmless opacity, with steam and vortex exceptions.
local function stronger(new_definition, old_definition)
    -- cloud.cc:_cloud_is_stronger preserves opaque harmless clouds unless
    -- their successor is also opaque. Steam and vortex are exceptions.
    return old_definition.harmless and
        (not old_definition.opaque or new_definition.opaque) or
        old_definition.id == ids.CLOUD_STEAM or
        new_definition.id == ids.CLOUD_VORTEX
end

-- Explicit attribution wins; otherwise a charmed or friendly source credits the friendly missile category.
local function source_credit(ctx, source_actor, options)
    if options.kill_category or options.killer_type then
        if not options.kill_category or not options.killer_type then
            error("cloud attribution requires category and killer type")
        end

        return options.kill_category, options.killer_type
    end

    if source_actor == ctx:player() then
        return attribution.PLAYER, attribution.PLAYER_MISSILE
    end

    if source_actor then
        if targets.allied(ctx, source_actor) then
            return attribution.FRIENDLY, attribution.MONSTER_MISSILE
        end

        return attribution.OTHER, attribution.MONSTER_MISSILE
    end

    return attribution.OTHER, attribution.MISC
end

-- Look up an existing cloud before a second entity can occupy its cell.
function placement.at(ctx, level_id, x, y)
    for _, entity in ipairs(ctx:query({ component.WORLD_CLOUD })) do
        local state = ctx:get(entity, component.WORLD_CLOUD)

        if state and state.level_id == level_id and
            state.x == x and state.y == y then
            return entity, state
        end
    end

    return nil
end

-- Resolve kind, terrain, occupancy, and source metadata in one place before creating a world cloud.
-- Example: ink may occupy water, while a competing cloud replaces an occupant only when stronger() permits it.
function placement.place(ctx, kind_id, source_actor,
    level_id, x, y, duration_aut, options)
    if duration_aut < 1 then
        return nil
    end

    kind_id = resolve_kind(ctx, kind_id)
    local definition = content.get(categories.CLOUDS, kind_id)

    if not ctx:walkable(level_id, x, y) then
        return nil
    end

    if not placement.terrain_eligible(kind_id,
        ctx:cell(level_id, x, y)) then
        return nil
    end

    options = options or {}

    if options.sanctuary and not definition.harmless then
        return nil
    end

    if wind.active_level(ctx, level_id) and
        kind_id ~= ids.CLOUD_VORTEX and
        kind_id ~= ids.CLOUD_INK then
        return nil
    end

    local entity, old_state = placement.at(ctx, level_id, x, y)

    if old_state then
        local old_definition = content.get(categories.CLOUDS,
            old_state.kind_id)

        if not stronger(definition, old_definition) then
            return nil
        end
    end

    local kill_category, killer_type = source_credit(
        ctx, source_actor, options)
    local source_id = options.source_actor_id or
        (source_actor and ctx:id(source_actor) or 0)

    local state = {
        kind_id = kind_id,
        level_id = level_id,
        x = x,
        y = y,
        decay_aut = duration_aut,
        spread_rate = options.spread_rate or definition.spread_rate,
        exclusion_radius = options.exclusion_radius or 0,
        source_actor_id = source_id,
        kill_category = kill_category,
        killer_type = killer_type,
        opaque = definition.opaque,
        special_ints = options.special_ints or {},
    }

    if entity then
        ctx:set(entity, component.WORLD_CLOUD, state)

        return entity
    end

    entity = ctx:create()
    ctx:add(entity, component.WORLD_CLOUD, state)

    return entity
end

-- Cloud removal must destroy the entity so occupancy and effect queries agree.
function placement.remove(ctx, entity)
    if ctx:get(entity, component.WORLD_CLOUD) then
        ctx:destroy(entity)
    end
end

return placement
