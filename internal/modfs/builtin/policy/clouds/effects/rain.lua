-- cloud.cc:_maybe_leave_water runs when a rain cloud is deleted.
local categories = require("constants.catalog")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")
local ids = require("ids.clouds")
local temporary = require("policy.world.temporary_terrain")
local component = require("constants.component")
local catalog = require("policy.catalog")
local fiery = require("policy.monsters.fiery")
local intelligence = require("constants.monster_intelligence")
local flags = require("constants.monster_flags")
local health = require("policy.combat.monster_health")

local rain = {}

-- Resolve a monster definition before testing fiery susceptibility.
local function monster_kind(ctx, actor)
    local state = ctx:get(actor, component.ACTOR)

    return state and catalog.get(categories.MONSTERS, state.kind_id) or nil
end

-- Rain harms fiery monsters but treats the player as immune to direct contact.
function rain.immune(ctx, actor)
    if actor == ctx:player() then
        return true
    end

    local definition = monster_kind(ctx, actor)

    return not definition or not fiery.is(definition.id)
end

-- Apply rain damage only to fiery actors, scaled by their action speed.
function rain.apply(ctx, actor, state, _, _, definition)
    if rain.immune(ctx, actor) then
        return 0
    end

    local raw = ctx:random(streams.CLOUDS,
        definition.damage.random)
    local speed = math.max(1,
        ctx:get(actor, component.ACTOR).speed)
    local amount = math.floor(raw * 10 / speed)

    if amount > 0 then
        local source = state.source_actor_id > 0 and
            ctx:entity(state.source_actor_id) or nil
        health.damage(ctx, actor, amount, source)
    end

    return amount
end

-- Fiery monsters avoid rain carefully; flying or aquatic monsters can ignore its water hazard.
function rain.avoid(ctx, monster, state, careful)
    local definition = monster_kind(ctx, monster)

    if fiery.is(definition.id) and careful then
        return true
    end

    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.FLIES then
            return false
        end
    end

    if definition.habitat_id == "HT_WATER" or
        definition.habitat_id == "HT_AMPHIBIOUS" then
        return false
    end

    if ctx:cell(state.level_id, state.x, state.y) ==
        terrain.DNGN_SHALLOW_WATER and
        definition.intelligence_id ~= intelligence.BRAINLESS then
        return true
    end

    return nil
end

-- On expiry, floor can become shallow water and shallow water may deepen.
local function changed_feature(ctx, state)
    local current = ctx:cell(state.level_id, state.x, state.y)

    if current == terrain.DNGN_FLOOR then
        return terrain.DNGN_SHALLOW_WATER
    end

    if current ~= terrain.DNGN_SHALLOW_WATER then
        return nil
    end

    local occupant = ctx:actor_at(state.level_id, state.x, state.y)

    if occupant == ctx:player() then
        return nil
    end

    if ctx:level_branch(state.level_id) == "sprint" then
        return nil
    end

    if ctx:random(streams.CLOUDS, 3) == 0 then
        return terrain.DNGN_DEEP_WATER
    end

    return nil
end

-- An expiry roll may turn the underlying terrain wetter; ordinary cloud aging does not do so.
-- Example: one in five expiries can wet floor, or deepen existing shallow water on a separate draw.
function rain.expire(ctx, _, state)
    if ctx:random(streams.CLOUDS, 5) ~= 0 then
        return false
    end

    local feature = changed_feature(ctx, state)

    if not feature then
        return false
    end

    local source

    if state.source_actor_id and state.source_actor_id > 0 then
        source = ctx:entity(state.source_actor_id)
    end

    local duration = 500 + ctx:random(streams.CLOUDS, 501)

    temporary.place(ctx, source, ids.CLOUD_RAIN,
        state.level_id, state.x, state.y, feature, duration)

    return false
end

return rain
