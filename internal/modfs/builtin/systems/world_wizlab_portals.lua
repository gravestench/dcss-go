-- Theory of operation: each Wizard Lab gate is an ECS entity with one saved
-- deadline. Global action time advances when the player acts on any floor,
-- so magic can close a gate while its Dungeon level is inactive. Accepted
-- travel at the gate gets to finish before the expiry mutation runs.
local component = require("constants.component")
local wizlab = require("constants.wizlab")
local signals = require("constants.world_signals")
local silence = require("policy.world.silence")
local terrain = require("constants.terrain")

local system = {}

-- Source player_can_hear tests Silence at both endpoints and allows a
-- 999-cell distance by default. The adjective bands below do not limit
-- hearing; they only describe how far away the magical portal sounds.
local function audible(ctx, state, position)
    if state.level_id ~= position.level_id then
        return false
    end

    local distance = math.max(math.abs(state.x - position.x),
        math.abs(state.y - position.y))

    return distance <= wizlab.MAX_HEARING_DISTANCE and
        not silence.at(ctx, state.level_id, state.x, state.y) and
        not silence.at(ctx, position.level_id,
            position.x, position.y)
end

-- Source timed_msg puts a distance phrase around its crackling sound.
-- The nearest bands place "nearby" after the noun, as the source does.
local function portal_description(state, position)
    local distance = math.max(math.abs(state.x - position.x),
        math.abs(state.y - position.y))

    if distance >= wizlab.VERY_DISTANT_AT then
        return "a very distant magical portal"
    end

    if distance >= wizlab.DISTANT_AT then
        return "a distant magical portal"
    end

    if distance >= wizlab.NEARBY_AT then
        return "a magical portal nearby"
    end

    if distance >= wizlab.VERY_NEARBY_AT then
        return "a magical portal very nearby"
    end

    return "a magical portal"
end

-- These are the source Wizard Lab timer's remaining-aut bands. The adjective
-- changes with the saved clock, never with a second random draw.
local function crackle_speed(remaining)
    if remaining > wizlab.SLOW_ABOVE_AUT then
        return "slow "
    end

    if remaining > wizlab.ORDINARY_ABOVE_AUT then
        return ""
    end

    if remaining > wizlab.BRISK_ABOVE_AUT then
        return "brisk "
    end

    if remaining > wizlab.URGENT_ABOVE_AUT then
        return "urgent "
    end

    return "frantic "
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

    if remaining <= wizlab.FINAL_WARNING_AUT and
        not state.final_warning then
        state.final_warning = true

        if audible(ctx, state, position) then
            ctx:emit("stairs",
                "The crackle of the magical portal is almost imperceptible now.")
        end
    elseif due then
        local description

        if audible(ctx, state, position) then
            description = portal_description(state, position)
        end

        if description then
            ctx:emit("stairs", "You hear the " ..
                crackle_speed(remaining) .. "crackle of " ..
                description .. ".")
        end

        local interval = remaining > wizlab.SHORT_NOTICE_BELOW_AUT and
            wizlab.LONG_NOTICE_AUT or wizlab.SHORT_NOTICE_AUT

        state.next_notice_aut = now + interval
    else
        return
    end

    ctx:set(entity, component.WORLD_WIZLAB_PORTAL, state)
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
        ctx:emit("stairs", "The flow of magic halts.")
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
        ctx:emit("stairs", "You hear the crackle of arcane power.")
        ctx:emit("stairs",
            "There is an entrance to a wizard's laboratory on " ..
            "this level! Hurry and find it before the " ..
            "portal closes forever!")
    end

    state.announced = true
    ctx:set(entity, component.WORLD_WIZLAB_PORTAL, state)
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
        terrain.DNGN_ENTER_WIZLAB then
        ctx:set_cell(state.level_id, state.x, state.y,
            terrain.DNGN_STONE_ARCH)

        announce_expiry(ctx, state, player_position)
    end

    state.spent = true
    ctx:set(entity, component.WORLD_WIZLAB_PORTAL, state)
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

    for _, entity in ipairs(ctx:query({ component.WORLD_WIZLAB_PORTAL })) do
        local state = ctx:get(entity, component.WORLD_WIZLAB_PORTAL)

        announce(ctx, entity, state, position, now)
        warn(ctx, entity, state, position, now)
        expire(ctx, entity, state, position, now, travelling)
    end
end

register.system({
    id = "world.wizlab_portals",
    scope = "active",
    query = {},
    after = { "status.constriction" },
    before = { "actor.death" },
    update = system.update,
})

return system
