-- Theory of operation: one ECS clock runs for each realized Ice Cave gate.
-- Player action time advances it even on an inactive outside floor. The
-- accepted travel signal lets a last-turn entry finish before expiry.
local component = require("constants.component")
local ice_cave = require("constants.ice_cave")
local signals = require("constants.world_signals")
local silence = require("policy.world.silence")
local terrain = require("constants.terrain")

local system = {}

-- Source hearing checks Silence at the arch and at the player. Distance
-- affects wording but only the 999-cell hearing limit affects audibility.
local function audible(ctx, state, position)
    if state.level_id ~= position.level_id then
        return false
    end

    local distance = math.max(math.abs(state.x - position.x),
        math.abs(state.y - position.y))

    return distance <= ice_cave.MAX_HEARING_DISTANCE and
        not silence.at(ctx, state.level_id, state.x, state.y) and
        not silence.at(ctx, position.level_id,
            position.x, position.y)
end

-- Timed messages call the arch very distant, distant, nearby, or very
-- nearby based on the same source distance bands as other portal sounds.
local function arch_description(state, position)
    local distance = math.max(math.abs(state.x - position.x),
        math.abs(state.y - position.y))

    if distance >= ice_cave.VERY_DISTANT_AT then
        return "a very distant melting archway"
    end

    if distance >= ice_cave.DISTANT_AT then
        return "a distant melting archway"
    end

    if distance >= ice_cave.NEARBY_AT then
        return "a melting archway nearby"
    end

    if distance >= ice_cave.VERY_NEARBY_AT then
        return "a melting archway very nearby"
    end

    return "a melting archway"
end

-- Five source bands describe how urgently the ice crackles as the saved
-- deadline approaches. No draw or new timer is made at notice time.
local function crackle_speed(remaining)
    if remaining > ice_cave.FAINT_ABOVE_AUT then
        return "faint "
    end

    if remaining > ice_cave.PLAIN_ABOVE_AUT then
        return ""
    end

    if remaining > ice_cave.STEADY_ABOVE_AUT then
        return "steady "
    end

    if remaining > ice_cave.QUICK_ABOVE_AUT then
        return "quick "
    end

    return "loud "
end

-- After the first fifty turns, normal notices are fifty turns apart;
-- the last ninety turns use shorter intervals and one final warning.
local function warn(ctx, entity, state, position, now)
    if state.spent or not state.announced or
        state.final_warning or now >= state.expires_aut then
        return
    end

    local remaining = state.expires_aut - now
    local due = now > state.next_notice_aut

    if remaining <= ice_cave.FINAL_WARNING_AUT then
        state.final_warning = true

        if audible(ctx, state, position) then
            ctx:emit("stairs",
                "The crackling of melting ice is subsiding rapidly.")
        end
    elseif due then
        if audible(ctx, state, position) then
            ctx:emit("stairs", "You hear the " ..
                crackle_speed(remaining) .. "crackling of " ..
                arch_description(state, position) .. ".")
        end

        local interval = remaining > ice_cave.SHORT_NOTICE_BELOW_AUT and
            ice_cave.LONG_NOTICE_AUT or ice_cave.SHORT_NOTICE_AUT

        state.next_notice_aut = now + interval
    else
        return
    end

    ctx:set(entity, component.WORLD_ICE_CAVE_PORTAL, state)
end

-- Visible expiry uses the marker's authored disappearance sentence.
-- Off-floor expiry changes the saved grid without narrating unseen events.
local function announce_expiry(ctx, state, position)
    if state.level_id ~= position.level_id then
        return
    end

    if ctx:visible(state.level_id, position.x, position.y,
        7, state.x, state.y) then
        ctx:emit("stairs", "The archway melts and disappears.")
    else
        ctx:emit("stairs",
            "The walls and floor vibrate strangely for a moment.")
    end
end

-- Discovery belongs to the chosen floor, not merely a first sighting of
-- its portal. An inaudible discovery does not replay after moving closer.
local function announce(ctx, entity, state, position, now)
    if state.announced or state.spent or
        now >= state.expires_aut or
        state.level_id ~= position.level_id then
        return
    end

    if audible(ctx, state, position) then
        ctx:emit("stairs", "You feel a wave of frost pass over you.")
        ctx:emit("stairs",
            "There is an entrance to an ice cave on this level. " ..
            "Hurry and find it before the portal melts!")
    end

    state.announced = true
    ctx:set(entity, component.WORLD_ICE_CAVE_PORTAL, state)
end

-- The authored expired portal remains in the grid and its spent ECS
-- clock records why it closed, so restore can check both witnesses.
local function expire(ctx, entity, state, position, now, travelling)
    if state.spent or now < state.expires_aut then
        return
    end

    if travelling and state.level_id == position.level_id and
        state.x == position.x and state.y == position.y then
        return
    end

    if ctx:cell(state.level_id, state.x, state.y) ==
        terrain.DNGN_ENTER_ICE_CAVE then
        ctx:set_cell(state.level_id, state.x, state.y,
            terrain.DNGN_EXPIRED_PORTAL)
        announce_expiry(ctx, state, position)
    end

    state.spent = true
    state.closure_reason = ice_cave.CLOSURE_EXPIRY
    ctx:set(entity, component.WORLD_ICE_CAVE_PORTAL, state)
end

-- Scheduler context starts before the accepted action. Include its cost
-- so an off-floor gate expires on time, without a one-turn lag.
function system.update(ctx, actor, delta)
    if actor ~= ctx:player() then
        return
    end

    local position = ctx:get(actor, component.POSITION)

    if not position then
        return
    end

    local now = ctx:aut() + delta
    local travelling = #ctx:signals(signals.PORTAL_TRAVEL) > 0

    for _, entity in ipairs(ctx:query({ component.WORLD_ICE_CAVE_PORTAL })) do
        local state = ctx:get(entity, component.WORLD_ICE_CAVE_PORTAL)

        announce(ctx, entity, state, position, now)
        warn(ctx, entity, state, position, now)
        expire(ctx, entity, state, position, now, travelling)
    end
end

register.system({
    id = "world.ice_cave_portals",
    scope = "active",
    query = {},
    after = { "status.constriction" },
    before = { "actor.death" },
    update = system.update,
})

return system
