-- In source DCSS, Protection is an aura refreshed by a qualifying hit.
-- Merely wielding a branded weapon grants no AC; the aura persists after
-- swapping weapons until its short saved duration runs out.
local component = require("constants.component")
local streams = require("constants.rng_streams")

local protection = {}

-- Each hit adds three or four turns, capped at five. The attack consumes
-- elapsed aut later in the same turn, as with other source durations.
function protection.refresh(ctx, player)
    local state = ctx:get(player, component.WEAPON_PROTECTION)
    local was_active = state and state.remaining_aut > 0
    local added = (3 + ctx:random(streams.MELEE, 2)) * 10

    state = state or { remaining_aut = 0 }
    state.remaining_aut = math.min(50, state.remaining_aut + added)

    if was_active then
        ctx:set(player, component.WEAPON_PROTECTION, state)
    else
        ctx:add(player, component.WEAPON_PROTECTION, state)
        ctx:emit("combat", "Your weapon exudes an aura of protection.")
    end
end

-- AC reads the same saved timer that the turn system ages; this also lets
-- the UI and save restore see the precise time left on the aura.
function protection.active(ctx, player)
    local state = ctx:get(player, component.WEAPON_PROTECTION)

    return state ~= nil and state.remaining_aut > 0
end

-- Expired aura state is removed so a later hit emits the start message
-- again and does not inherit time from an earlier Protection weapon.
function protection.tick(ctx, player, aut)
    local state = ctx:get(player, component.WEAPON_PROTECTION)

    if not state then
        return
    end

    state.remaining_aut = math.max(0, state.remaining_aut - aut)

    if state.remaining_aut == 0 then
        ctx:remove(player, component.WEAPON_PROTECTION)
        ctx:emit("duration", "Your protective aura fades away.")

        return
    end

    ctx:set(player, component.WEAPON_PROTECTION, state)
end

return protection
