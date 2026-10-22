-- Theory of operation: each Bailey gate is an ECS entity with one saved
-- deadline. Global action time advances when the player acts on any floor,
-- so the portcullis can close while its Dungeon level is inactive. Accepted
-- travel at the gate gets to finish before the expiry mutation runs.
local component = require("constants.component")
local bailey = require("constants.bailey")
local signals = require("constants.world_signals")
local silence = require("policy.world.silence")
local terrain = require("constants.terrain")

local system = {}

-- Source player_can_hear tests Silence at both endpoints and allows a
-- 999-cell distance by default. The adjective bands below do not limit
-- hearing; they describe the distance of the creaking portcullis.
local function audible(ctx, state, position)
    if state.level_id ~= position.level_id then
        return false
    end

    local distance = math.max(math.abs(state.x - position.x),
        math.abs(state.y - position.y))

    return distance <= bailey.MAX_HEARING_DISTANCE and
        not silence.at(ctx, state.level_id, state.x, state.y) and
        not silence.at(ctx, position.level_id,
            position.x, position.y)
end

-- The source timed_msg distance adjective changes the noisemaker phrase,
-- while the speed adjective below depends only on time remaining.
local function portcullis_description(state, position)
    local distance = math.max(math.abs(state.x - position.x),
        math.abs(state.y - position.y))

    if distance >= bailey.VERY_DISTANT_AT then
        return "a very distant portcullis"
    end

    if distance >= bailey.DISTANT_AT then
        return "a distant portcullis"
    end

    if distance >= bailey.NEARBY_AT then
        return "a portcullis nearby"
    end

    if distance >= bailey.VERY_NEARBY_AT then
        return "a portcullis very nearby"
    end

    return "a portcullis"
end

-- These are the source Bailey timer's remaining-aut bands. The adjective
-- changes with the saved clock, never with a second random draw.
local function creak_speed(remaining)
    if remaining > bailey.FAINT_ABOVE_AUT then
        return "faint "
    end

    if remaining > bailey.PLAIN_ABOVE_AUT then
        return ""
    end

    if remaining > bailey.STEADY_ABOVE_AUT then
        return "steady "
    end

    if remaining > bailey.QUICK_ABOVE_AUT then
        return "quick "
    end

    return "loud "
end

-- Source timed_msg waits fifty turns, then checks every fifty turns until
-- the last ninety; its late checks are twenty-five turns apart. An action
-- crossing several checks emits only one message, as the source event does.
local function warn(ctx, entity, state, position, now)
    if state.spent or not state.announced or
        state.final_warning or
        now >= state.expires_aut then
        return
    end

    local remaining = state.expires_aut - now
    local due = now > state.next_notice_aut

    if remaining <= bailey.FINAL_WARNING_AUT and
        not state.final_warning then
        state.final_warning = true

        if audible(ctx, state, position) then
            ctx:emit("stairs",
                "The portcullis has been lowered almost to the ground.")
        end
    elseif due then
        local description

        if audible(ctx, state, position) then
            description = portcullis_description(state, position)
        end

        if description then
            ctx:emit("stairs", "You hear the " ..
                creak_speed(remaining) .. "creaking of " ..
                description .. ".")
        end

        local interval = remaining > bailey.SHORT_NOTICE_BELOW_AUT and
            bailey.LONG_NOTICE_AUT or bailey.SHORT_NOTICE_AUT

        state.next_notice_aut = now + interval
    else
        return
    end

    ctx:set(entity, component.WORLD_BAILEY_PORTAL, state)
end

-- A visible gate uses its authored disappearance line. The source timed
-- marker reports a brief vibration when the gate expires outside sight;
-- inactive floors change their saved grid silently until the player returns.
local function announce_expiry(ctx, state, player_position)
    if state.level_id ~= player_position.level_id then
        return
    end

    if ctx:visible(state.level_id, player_position.x,
        player_position.y, 7, state.x, state.y) then
        ctx:emit("stairs", "The portal closes with a thud.")
    else
        ctx:emit("stairs",
            "The walls and floor vibrate strangely for a moment.")
    end
end

-- The source's two discovery lines get one chance on first arrival. Its
-- timed messenger only emits when the portal is audible; moving closer
-- afterward must not replay the initial announcement.
local function announce(ctx, entity, state, player_position, now)
    if state.announced or state.spent or
        now >= state.expires_aut or
        state.level_id ~= player_position.level_id then
        return
    end

    if audible(ctx, state, player_position) then
        ctx:emit("stairs", "You hear the roar of battle.")
        ctx:emit("stairs",
            "There is an entrance to a bailey on this level. " ..
            "Hurry and find it before the portal closes forever!")
    end

    state.announced = true
    ctx:set(entity, component.WORLD_BAILEY_PORTAL, state)
end

-- The collapsed entrance stays as saved terrain and the spent component
-- remains to prove the authored marker and clock at restore time.
local function expire(ctx, entity, state, player_position, now,
    travelling)
    if state.spent or now < state.expires_aut then
        return
    end

    if travelling and state.level_id == player_position.level_id and
        state.x == player_position.x and
        state.y == player_position.y then
        return
    end

    if ctx:cell(state.level_id, state.x, state.y) ==
        terrain.DNGN_ENTER_BAILEY then
        ctx:set_cell(state.level_id, state.x, state.y,
            terrain.DNGN_STONE_ARCH)

        announce_expiry(ctx, state, player_position)
    end

    state.spent = true
    state.closure_reason = bailey.CLOSURE_EXPIRY
    ctx:set(entity, component.WORLD_BAILEY_PORTAL, state)
end

-- Scheduler context still carries start-of-action aut. Include the
-- accepted action's delta to expire on time rather than one turn late.
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

    for _, entity in ipairs(ctx:query({ component.WORLD_BAILEY_PORTAL })) do
        local state = ctx:get(entity, component.WORLD_BAILEY_PORTAL)

        announce(ctx, entity, state, position, now)
        warn(ctx, entity, state, position, now)
        expire(ctx, entity, state, position, now, travelling)
    end
end

register.system({
    id = "world.bailey_portals",
    scope = "active",
    query = {},
    after = { "status.constriction" },
    before = { "actor.death" },
    update = system.update,
})

return system
