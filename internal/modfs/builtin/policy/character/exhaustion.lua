-- Ru's powers use a saved player timer. The existing Berserk component also
-- carries its cooldown; read both while migrating toward one source status.
local component = require("constants.component")
local time = require("constants.time")

local exhaustion = {}

-- The source blocks every exhaustion-cost ability during either cooldown.
function exhaustion.active(ctx, player)
    local state = ctx:get(player, component.PLAYER_EXHAUSTION)
    local berserk = ctx:get(player, component.RAGE)

    return (state and state.remaining_aut > 0) or
        (berserk and berserk.remaining_aut > 0) or
        (berserk and berserk.cooldown_aut > 0) or false
end

-- Increase, rather than replace, the source duration after a paid ability.
function exhaustion.apply(ctx, player, turns)
    if type(turns) ~= "number" or turns <= 0 or turns % 1 ~= 0 then
        error("exhaustion requires positive whole turns")
    end

    local state = ctx:get(player, component.PLAYER_EXHAUSTION)
    local amount = turns * time.AUT_PER_TURN

    if state then
        state.remaining_aut = state.remaining_aut + amount
        ctx:set(player, component.PLAYER_EXHAUSTION, state)
    else
        ctx:add(player, component.PLAYER_EXHAUSTION, {
            remaining_aut = amount,
        })
    end
end

-- Aut-based decay keeps fast and slow actions equivalent in game time.
function exhaustion.tick(ctx, player, elapsed_aut)
    local state = ctx:get(player, component.PLAYER_EXHAUSTION)

    if not state or elapsed_aut <= 0 then
        return
    end

    state.remaining_aut = math.max(0,
        state.remaining_aut - elapsed_aut)

    if state.remaining_aut == 0 then
        ctx:remove(player, component.PLAYER_EXHAUSTION)
        ctx:emit("duration", "You are no longer exhausted.")
    else
        ctx:set(player, component.PLAYER_EXHAUSTION, state)
    end
end

-- Reject malformed saved timers before player systems resume.
function exhaustion.validate(ctx, player)
    local state = ctx:get(player, component.PLAYER_EXHAUSTION)

    if state and (state.remaining_aut <= 0 or
        state.remaining_aut > 60000) then
        error("invalid player exhaustion")
    end
end

return exhaustion
