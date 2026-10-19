-- Source: player.cc:player::sentinel_mark(true).
local component = require("constants.component")
local streams = require("constants.rng_streams")

local mark = {}

-- A fresh alarm mark updates the existing timer instead of stacking components.
function mark.apply(ctx, player, source_stream)
    local stream = source_stream or streams.TRAPS
    local state = ctx:get(player, component.TRAP_MARK)

    if state then
        state.remaining_aut = math.min(1800,
            state.remaining_aut + (20 + ctx:random(stream, 21)) * 10)
        ctx:set(player, component.TRAP_MARK, state)
        ctx:emit("trap", "The mark upon you grows brighter.")

        return
    end

    ctx:add(player, component.TRAP_MARK, {
        remaining_aut = (25 + ctx:random(stream, 16)) * 10,
    })
    ctx:emit("trap", "A sentinel's mark forms upon you.")
end

-- Decay the alarm mark on action time and remove it once duration reaches zero.
-- Example: mark.tick(ctx, player, 10) ages the alarm mark after a player action.
function mark.tick(ctx, player, aut)
    local state = ctx:get(player, component.TRAP_MARK)

    if not state or aut <= 0 then
        return
    end

    state.remaining_aut = state.remaining_aut - aut

    if state.remaining_aut <= 0 then
        ctx:remove(player, component.TRAP_MARK)
        ctx:emit("trap", "The sentinel's mark upon you fades away.")
    else
        ctx:set(player, component.TRAP_MARK, state)
    end
end

return mark
