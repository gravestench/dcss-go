local categories = require("constants.catalog")
local component = require("constants.component")
local attribution = require("constants.cloud_attribution")
local terrain_ids = require("constants.terrain")
local catalog = require("policy.catalog")
local placement = require("policy.clouds.placement")

local clouds = {}

local killers = {
    [attribution.PLAYER] = {
        [attribution.PLAYER_MISSILE] = true,
        [attribution.PLAYER_CONFUSION] = true,
    },
    [attribution.FRIENDLY] = {
        [attribution.MONSTER_MISSILE] = true,
        [attribution.MONSTER] = true,
        [attribution.PLAYER_CONFUSION] = true,
    },
    [attribution.OTHER] = {
        [attribution.MONSTER_MISSILE] = true,
        [attribution.MONSTER] = true,
        [attribution.MISCAST] = true,
        [attribution.MISC] = true,
    },
}

local known_terrain = {}

for _, id in pairs(terrain_ids) do
    known_terrain[id] = true
end

local function cell_key(state)
    return string.format("%d:%d:%d",
        state.level_id, state.x, state.y)
end

local function valid_integer(value, minimum, maximum)
    return type(value) == "number" and
        value % 1 == 0 and value >= minimum and
        (not maximum or value <= maximum)
end

local function validate_cloud(ctx, entity, state, occupied)
    local id = ctx:id(entity)
    local known, definition = pcall(catalog.get,
        categories.CLOUDS, state.kind_id)

    if not known then
        error("cloud " .. id .. " has unknown kind " .. state.kind_id)
    end

    if not valid_integer(state.decay_aut, 1) then
        error("cloud " .. id .. " has invalid decay")
    end

    if not valid_integer(state.spread_rate, 0, 100) or
        not valid_integer(state.exclusion_radius, -1) then
        error("cloud " .. id .. " has invalid spread")
    end

    if not killers[state.kill_category] or
        not killers[state.kill_category][state.killer_type] then
        error("cloud " .. id .. " has broken attribution")
    end

    if state.opaque ~= definition.opaque then
        error("cloud " .. id .. " has forged opacity")
    end

    if not ctx:walkable(state.level_id, state.x, state.y) then
        error("cloud " .. id .. " is outside walkable terrain")
    end

    if not placement.terrain_eligible(state.kind_id,
        ctx:cell(state.level_id, state.x, state.y)) then
        error("cloud " .. id .. " is ineligible for terrain")
    end

    local key = cell_key(state)

    if occupied[key] then
        error("duplicate clouds at " .. key)
    end

    occupied[key] = true
end

local function validate_terrain(ctx, entity, state, occupied)
    local id = ctx:id(entity)

    if not known_terrain[state.original_feature] or
        not known_terrain[state.changed_feature] or
        state.original_feature == state.changed_feature or
        not valid_integer(state.expires_aut, ctx:aut() + 1) or
        state.source_kind_id == "" then
        error("temporary terrain " .. id .. " is invalid")
    end

    local key = cell_key(state)

    if occupied[key] then
        error("duplicate temporary terrain at " .. key)
    end

    occupied[key] = true
end

function clouds.validate(ctx)
    local occupied_clouds = {}
    local occupied_terrain = {}

    for _, entity in ipairs(ctx:query({ component.WORLD_CLOUD })) do
        validate_cloud(ctx, entity,
            ctx:get(entity, component.WORLD_CLOUD), occupied_clouds)
    end

    for _, entity in ipairs(ctx:query({
        component.TEMPORARY_TERRAIN,
    })) do
        validate_terrain(ctx, entity,
            ctx:get(entity, component.TEMPORARY_TERRAIN),
            occupied_terrain)
    end

    for _, entity in ipairs(ctx:query({ component.CORROSION })) do
        local state = ctx:get(entity, component.CORROSION)

        if entity ~= ctx:player() or
            not valid_integer(state.remaining_aut, 1, 500) or
            not valid_integer(state.stacks, 1, 100) then
            error("invalid player corrosion")
        end
    end

    return {}
end

register.policy({
    id = "save.validate_clouds",
    run = clouds.validate,
})

return clouds
