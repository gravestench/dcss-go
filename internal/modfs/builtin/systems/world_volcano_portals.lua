-- Theory of operation: one ECS clock runs for each realized Volcano gate.
-- Player action time advances it even on an inactive outside floor. The
-- accepted travel signal lets a last-turn entry finish before expiry.
local component = require("constants.component")
local channels = require("constants.message_channels")
local volcano = require("constants.volcano")
local signals = require("constants.world_signals")
local silence = require("policy.world.silence")
local terrain = require("constants.terrain")

local system = {}

-- Source hearing checks Silence at the tunnel and at the player. Distance
-- affects wording but only the 999-cell hearing limit affects audibility.
local function audible(ctx, state, position)
    if state.level_id ~= position.level_id then
        return false
    end

    local distance = math.max(math.abs(state.x - position.x),
        math.abs(state.y - position.y))

    return distance <= volcano.MAX_HEARING_DISTANCE and
        not silence.at(ctx, state.level_id, state.x, state.y) and
        not silence.at(ctx, position.level_id,
            position.x, position.y)
end

-- The source timed messenger qualifies its noisemaker by Chebyshev
-- distance, then chooses the English article. The tunnel is the gate,
-- whereas the heard sound comes from an avalanche of rocks.
local function noise_description(state, position)
    local distance = math.max(math.abs(state.x - position.x),
        math.abs(state.y - position.y))

    if distance >= volcano.VERY_DISTANT_AT then
        return "a very distant " .. volcano.PORTAL_NOISEMAKER
    end

    if distance >= volcano.DISTANT_AT then
        return "a distant " .. volcano.PORTAL_NOISEMAKER
    end

    if distance >= volcano.NEARBY_AT then
        return "an " .. volcano.PORTAL_NOISEMAKER .. " nearby"
    end

    if distance >= volcano.VERY_NEARBY_AT then
        return "an " .. volcano.PORTAL_NOISEMAKER .. " very nearby"
    end

    return "an " .. volcano.PORTAL_NOISEMAKER
end

-- Five source bands describe how urgently the rocks rumble as the saved
-- deadline approaches. No draw or new timer is made at notice time.
local function rumble_speed(remaining)
    if remaining > volcano.SLOW_ABOVE_AUT then
        return "slow "
    end

    if remaining > volcano.BRISK_ABOVE_AUT then
        return ""
    end

    if remaining > volcano.QUICK_ABOVE_AUT then
        return "brisk "
    end

    if remaining > volcano.RAPID_ABOVE_AUT then
        return "quick "
    end

    return "rapid "
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

    if remaining <= volcano.FINAL_WARNING_AUT then
        state.final_warning = true

        if audible(ctx, state, position) then
            ctx:emit(channels.STAIRS,
                "The sound of falling rocks suddenly begins to subside.")
        end
    elseif due then
        if audible(ctx, state, position) then
            ctx:emit(channels.STAIRS, "You hear a " ..
                rumble_speed(remaining) .. "rumble of " ..
                noise_description(state, position) .. ".")
        end

        local interval = remaining > volcano.SHORT_NOTICE_BELOW_AUT and
            volcano.LONG_NOTICE_AUT or volcano.SHORT_NOTICE_AUT

        state.next_notice_aut = now + interval
    else
        return
    end

    ctx:set(entity, component.WORLD_VOLCANO_PORTAL, state)
end

-- Visible expiry uses the marker's authored disappearance sentence.
-- Off-floor expiry changes the saved grid without narrating unseen events.
local function announce_expiry(ctx, state, position)
    if state.level_id ~= position.level_id then
        return
    end

    if ctx:visible(state.level_id, position.x, position.y,
        7, state.x, state.y) then
        ctx:emit(channels.STAIRS,
            "There is a deep roar from within the tunnel. " ..
            "Moments later, a river of lava pours forth, sealing it permanently.")
    else
        ctx:emit(channels.STAIRS,
            "You hear an avalanche of rocks in the distance.")
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
        ctx:emit(channels.STAIRS,
            "You feel an oppressive heat about you.")
        ctx:emit(channels.STAIRS,
            "There is an entrance to a volcano on this level. " ..
            "Hurry and find it before the entrance collapses!")
    end

    state.announced = true
    ctx:set(entity, component.WORLD_VOLCANO_PORTAL, state)
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
        terrain.DNGN_ENTER_VOLCANO then
        ctx:set_cell(state.level_id, state.x, state.y,
            terrain.DNGN_EXPIRED_PORTAL)
        announce_expiry(ctx, state, position)
    end

    state.spent = true
    state.closure_reason = volcano.CLOSURE_EXPIRY
    ctx:set(entity, component.WORLD_VOLCANO_PORTAL, state)
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

    for _, entity in ipairs(ctx:query({ component.WORLD_VOLCANO_PORTAL })) do
        local state = ctx:get(entity, component.WORLD_VOLCANO_PORTAL)

        announce(ctx, entity, state, position, now)
        warn(ctx, entity, state, position, now)
        expire(ctx, entity, state, position, now, travelling)
    end
end

register.system({
    id = "world.volcano_portals",
    scope = "active",
    query = {},
    after = { "status.constriction" },
    before = { "actor.death" },
    update = system.update,
})

return system
