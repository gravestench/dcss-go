-- Theory of operation: each Sewer drain is an ECS entity with one saved
-- deadline. Global action time advances when the player acts on any floor,
-- so a drain can rust away while its Dungeon level is inactive. Accepted
-- travel at the gate gets to finish before the expiry mutation runs.
local component = require("constants.component")
local signals = require("constants.world_signals")
local terrain = require("constants.terrain")

local system = {}

-- A visible drain uses the source disappearance line. A drain elsewhere
-- on the same floor uses the source hearing line; inactive floors change
-- their saved grid silently until the player returns.
local function announce_expiry(ctx, state, player_position)
    if state.level_id ~= player_position.level_id then
        return
    end

    if ctx:visible(state.level_id, player_position.x,
        player_position.y, 7, state.x, state.y) then
        ctx:emit("stairs", "The drain falls to bits.")
    else
        ctx:emit("stairs", "You hear the drain falling apart.")
    end
end

-- The source's two discovery lines belong to the first player arrival on
-- this level. Population may happen before the player moves onto the new
-- floor, so announcing at materialization would lose the message.
local function announce(ctx, entity, state, player_position, now)
    if state.announced or state.spent or
        now >= state.expires_aut or
        state.level_id ~= player_position.level_id then
        return
    end

    ctx:emit("stairs", "You hear the sound of rushing water.")
    ctx:emit("stairs", "There is an entrance to a sewer on this level. " ..
        "Hurry and find it before the portal rusts away!")

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
