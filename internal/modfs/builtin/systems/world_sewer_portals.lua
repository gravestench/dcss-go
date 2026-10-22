-- Theory of operation: each Sewer drain is an ECS entity with one saved
-- deadline. Global action time advances when the player acts on any floor,
-- so a drain can rust away while its Dungeon level is inactive. Accepted
-- travel at the gate gets to finish before the expiry mutation runs.
local component = require("constants.component")
local sewer = require("constants.sewer")
local signals = require("constants.world_signals")
local terrain = require("constants.terrain")

local system = {}

-- Source timed_msg chooses the article around "drain" from distance to
-- the portal. The source's farthest distance band supplies a bounded
-- hearing approximation until the generic sound owner is ported.
local function drain_description(state, position)
    local distance = math.max(math.abs(state.x - position.x),
        math.abs(state.y - position.y))

    if distance > sewer.HEARING_RADIUS then
        return nil
    end

    if distance >= sewer.VERY_DISTANT_AT then
        return "a very distant drain"
    end

    if distance >= sewer.DISTANT_AT then
        return "a distant drain"
    end

    if distance >= sewer.NEARBY_AT then
        return "a drain nearby"
    end

    if distance >= sewer.VERY_NEARBY_AT then
        return "a drain very nearby"
    end

    return "a drain"
end

-- These are the source Sewer timer's remaining-aut bands. The adjective
-- changes with the saved clock, never with a second random draw.
local function rust_speed(remaining)
    if remaining > sewer.SLOW_ABOVE_AUT then
        return "slow "
    end

    if remaining > sewer.ORDINARY_ABOVE_AUT then
        return ""
    end

    if remaining > sewer.BRISK_ABOVE_AUT then
        return "brisk "
    end

    if remaining > sewer.QUICK_ABOVE_AUT then
        return "quick "
    end

    return "rapid "
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

    if remaining <= sewer.FINAL_WARNING_AUT and
        not state.final_warning then
        state.final_warning = true

        if state.level_id == position.level_id and
            drain_description(state, position) then
            ctx:emit("stairs", "You hear the drain falling apart.")
        end
    elseif due then
        local description

        if state.level_id == position.level_id then
            description = drain_description(state, position)
        end

        if description then
            ctx:emit("stairs", "You hear the " ..
                rust_speed(remaining) .. "rusting of " ..
                description .. ".")
        end

        local interval = remaining > sewer.SHORT_NOTICE_BELOW_AUT and
            sewer.LONG_NOTICE_AUT or sewer.SHORT_NOTICE_AUT

        state.next_notice_aut = now + interval
    else
        return
    end

    ctx:set(entity, component.WORLD_SEWER_PORTAL, state)
end

-- A visible drain uses its authored disappearance line. The source timed
-- marker reports a brief vibration when the drain expires outside sight;
-- inactive floors change their saved grid silently until the player returns.
local function announce_expiry(ctx, state, player_position)
    if state.level_id ~= player_position.level_id then
        return
    end

    if ctx:visible(state.level_id, player_position.x,
        player_position.y, 7, state.x, state.y) then
        ctx:emit("stairs", "The drain falls to bits.")
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

    if drain_description(state, player_position) then
        ctx:emit("stairs", "You hear the sound of rushing water.")
        ctx:emit("stairs",
            "There is an entrance to a sewer on this level. " ..
            "Hurry and find it before the portal rusts away!")
    end

    state.announced = true
    ctx:set(entity, component.WORLD_SEWER_PORTAL, state)
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
        terrain.DNGN_ENTER_SEWER then
        ctx:set_cell(state.level_id, state.x, state.y,
            terrain.DNGN_EXPIRED_PORTAL)

        announce_expiry(ctx, state, player_position)
    end

    state.spent = true
    ctx:set(entity, component.WORLD_SEWER_PORTAL, state)
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

    for _, entity in ipairs(ctx:query({ component.WORLD_SEWER_PORTAL })) do
        local state = ctx:get(entity, component.WORLD_SEWER_PORTAL)

        announce(ctx, entity, state, position, now)
        warn(ctx, entity, state, position, now)
        expire(ctx, entity, state, position, now, travelling)
    end
end

register.system({
    id = "world.sewer_portals",
    scope = "active",
    query = {},
    after = { "status.constriction" },
    before = { "actor.death" },
    update = system.update,
})

return system
