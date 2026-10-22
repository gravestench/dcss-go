-- Theory of operation: each Bazaar entrance has its own saved ECS clock.
-- Global time advances even while the player is away from its outside
-- floor. A spent arch stays inert while the player shops inside.
local component = require("constants.component")
local signals = require("constants.world_signals")
local terrain = require("constants.terrain")

local system = {}

-- The clock may finish on another floor. Change that saved grid silently;
-- only the active floor can provide a sight or vibration message.
local function announce_expiry(ctx, state, player_position)
    if state.level_id ~= player_position.level_id then
        return
    end

    if ctx:visible(state.level_id, player_position.x,
        player_position.y, 7, state.x, state.y) then
        ctx:emit("stairs", "The gate to the bazaar disappears!")
    else
        ctx:emit("stairs",
            "The walls and floor vibrate strangely for a moment.")
    end
end

-- Restore the inert stone arch after the source deadline. The marker stays
-- as spent evidence for save validation and cannot be used a second time.
local function expire(ctx, entity, state, player_position, now,
    travelling)
    if state.spent or not state.timed or
        now < state.expires_aut then
        return
    end

    if travelling and state.level_id == player_position.level_id and
        state.x == player_position.x and
        state.y == player_position.y then
        return
    end

    if ctx:cell(state.level_id, state.x, state.y) ==
        terrain.DNGN_ENTER_BAZAAR then
        ctx:set_cell(state.level_id, state.x, state.y,
            terrain.DNGN_STONE_ARCH)

        announce_expiry(ctx, state, player_position)
    end

    state.spent = true
    ctx:set(entity, component.WORLD_BAZAAR_PORTAL, state)
end

-- The scheduler calls this before the host advances ctx:aut(). Add this
-- player's elapsed aut so the arch disappears on the action that reaches
-- its deadline, rather than surviving one extra action and invalidating
-- the saved clock. A portal action already accepted at the start of the
-- turn gets to finish; its travel commit spends the arch instead.
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

    for _, entity in ipairs(ctx:query({ component.WORLD_BAZAAR_PORTAL })) do
        local state = ctx:get(entity, component.WORLD_BAZAAR_PORTAL)

        expire(ctx, entity, state, position, now, travelling)
    end
end

register.system({
    id = "world.bazaar_portals",
    scope = "active",
    query = {},
    after = { "status.constriction" },
    before = { "actor.death" },
    update = system.update,
})

return system
