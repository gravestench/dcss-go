-- Theory of operation: each Gauntlet entrance owns a saved deadline.
-- The world clock advances on every player action, including actions on
-- other floors. This system makes the source's distant drum warnings and
-- finally closes the outside gate as a stone arch. Accepted stair travel
-- completes before expiry mutates the cell under the visitor.
local component = require("constants.component")
local gauntlet = require("constants.gauntlet")
local signals = require("constants.world_signals")
local silence = require("policy.world.silence")
local terrain = require("constants.terrain")

local system = {}

-- Source player_can_hear checks silence at both endpoints. Distance
-- changes the wording of drumbeats, while the deadline changes volume.
local function audible(ctx, state, position)
    if state.level_id ~= position.level_id then
        return false
    end

    local distance = math.max(math.abs(state.x - position.x),
        math.abs(state.y - position.y))

    return distance <= gauntlet.MAX_HEARING_DISTANCE and
        not silence.at(ctx, state.level_id, state.x, state.y) and
        not silence.at(ctx, position.level_id,
            position.x, position.y)
end

-- The source messenger has the same near/distant distance bands used by
-- other temporary gates, but its noun is an audible drum.
local function drum_description(state, position)
    local distance = math.max(math.abs(state.x - position.x),
        math.abs(state.y - position.y))

    if distance >= gauntlet.VERY_DISTANT_AT then
        return "a very distant drum"
    end

    if distance >= gauntlet.DISTANT_AT then
        return "a distant drum"
    end

    if distance >= gauntlet.NEARBY_AT then
        return "a drum nearby"
    end

    if distance >= gauntlet.VERY_NEARBY_AT then
        return "a drum very nearby"
    end

    return "a drum"
end

-- The source `timed_msg` range table maps remaining aut to five volume
-- phrases. No new random draw occurs for a warning.
local function drum_strength(remaining)
    if remaining > gauntlet.FAINT_ABOVE_AUT then
        return "faint "
    end

    if remaining > gauntlet.PLAIN_ABOVE_AUT then
        return ""
    end

    if remaining > gauntlet.LOUD_ABOVE_AUT then
        return "loud "
    end

    if remaining > gauntlet.THUNDEROUS_ABOVE_AUT then
        return "thunderous "
    end

    return "deafening "
end

-- Source timers become more urgent near closure. A long action may cross
-- several thresholds; one warning at its end avoids a burst of stale text.
local function warn(ctx, entity, state, position, now)
    if state.spent or not state.announced or
        now >= state.expires_aut or
        now <= state.next_notice_aut then
        return
    end

    local remaining = state.expires_aut - now

    if audible(ctx, state, position) then
        ctx:emit("stairs", "You hear the " ..
            drum_strength(remaining) .. "beating of " ..
            drum_description(state, position) .. ".")
    end

    local interval = remaining > gauntlet.SHORT_NOTICE_BELOW_AUT and
        gauntlet.LONG_NOTICE_AUT or gauntlet.SHORT_NOTICE_AUT

    state.next_notice_aut = now + interval
    ctx:set(entity, component.WORLD_GAUNTLET_PORTAL, state)
end

-- The source init message is heard once when the outside level is
-- active. Revisiting or restoring never replays it or restarts the gate.
local function announce(ctx, entity, state, position, now)
    if state.announced or state.spent or
        now >= state.expires_aut or
        state.level_id ~= position.level_id then
        return
    end

    if audible(ctx, state, position) then
        ctx:emit("stairs", "You hear a distant snort.")
        ctx:emit("stairs",
            "Hark! There is a gateway to a gauntlet on this level. " ..
            "Find the entrance quickly before the gate is sealed!")
    end

    state.announced = true
    ctx:set(entity, component.WORLD_GAUNTLET_PORTAL, state)
end

-- A closed gate keeps its ECS witness for save validation. The source
-- final drum message is local; an inactive outside floor changes silently.
local function expire(ctx, entity, state, position, now, travelling)
    if state.spent or now < state.expires_aut then
        return
    end

    if travelling and state.level_id == position.level_id and
        state.x == position.x and state.y == position.y then
        return
    end

    if ctx:cell(state.level_id, state.x, state.y) ==
        terrain.DNGN_ENTER_GAUNTLET then
        ctx:set_cell(state.level_id, state.x, state.y,
            terrain.DNGN_STONE_ARCH)

        if audible(ctx, state, position) then
            ctx:emit("stairs",
                "After a thunderous strike, the drumbeats cease.")
        end
    end

    state.spent = true
    ctx:set(entity, component.WORLD_GAUNTLET_PORTAL, state)
end

-- The scheduler carries start-of-action aut, so include this action's
-- delta to close exactly on the source deadline rather than one turn late.
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

    for _, entity in ipairs(ctx:query({ component.WORLD_GAUNTLET_PORTAL })) do
        local state = ctx:get(entity, component.WORLD_GAUNTLET_PORTAL)

        announce(ctx, entity, state, position, now)
        warn(ctx, entity, state, position, now)
        expire(ctx, entity, state, position, now, travelling)
    end
end

register.system({
    id = "world.gauntlet_portals",
    scope = "active",
    query = {},
    after = { "status.constriction" },
    before = { "actor.death" },
    update = system.update,
})

return system
