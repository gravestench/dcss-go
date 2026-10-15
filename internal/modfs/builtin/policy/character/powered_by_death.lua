local component = require("constants.component")

local powered = {}

local function duration(ctx)
    return (2 + ctx:random("mutation", 4)) * 10
end

function powered.strength(ctx, player)
    local state = ctx:get(player, component.POWERED_BY_DEATH)

    if not state or state.remaining_aut <= 0 then
        return 0
    end

    return state.strength
end

-- Source: mon-death.cc gives a fresh 2-5 turn timer before testing the
-- decreasing chance to add another strength stack.
function powered.on_kill(ctx, player, _, level)
    local state = ctx:get(player, component.POWERED_BY_DEATH)
    local previous = state and state.strength or 0
    local next_state = state or {
        strength = 0,
        remaining_aut = 0,
    }

    next_state.remaining_aut = duration(ctx)

    if ctx:random("mutation", 10) < 10 - previous then
        next_state.strength = previous + ctx:random("mutation", 1 + level)
    end

    if state then
        ctx:set(player, component.POWERED_BY_DEATH, next_state)
    else
        ctx:add(player, component.POWERED_BY_DEATH, next_state)
    end
end

-- Source: player-reacts.cc loses one strength whenever the duration ends.
-- An active stack gets a new 2-5 turn timer until all stacks expire.
function powered.tick(ctx, player, aut)
    local state = ctx:get(player, component.POWERED_BY_DEATH)

    if not state or state.strength <= 0 or aut <= 0 then
        return
    end

    state.remaining_aut = math.max(0, state.remaining_aut - aut)

    if state.remaining_aut == 0 then
        state.strength = state.strength - 1

        if state.strength > 0 then
            state.remaining_aut = duration(ctx)
        end
    end

    ctx:set(player, component.POWERED_BY_DEATH, state)
end

return powered
