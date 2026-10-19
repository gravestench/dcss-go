local confusion = {}
local zap = require("policy.magic.effects.zaps.ids").component

-- Store confusion in aut and cap it at 400 so repeated effects cannot create an unbounded delay.
function confusion.extend(ctx, player, turns)
    local state = ctx:get(player, zap.PLAYER_CONFUSION)
    local added = turns * 10

    if state then
        state.remaining_aut = math.min(400,
            state.remaining_aut + added)
        ctx:set(player, zap.PLAYER_CONFUSION, state)
    else
        ctx:add(player, zap.PLAYER_CONFUSION, {
            remaining_aut = math.min(400, added),
        })
    end
end

-- Example: a saved confusion state with zero remaining aut cannot redirect the next move.
-- Check remaining aut so an expired component cannot redirect a move before cleanup.
function confusion.active(ctx, player)
    local state = ctx:get(player, "zap.player_confusion")

    return state ~= nil and state.remaining_aut > 0
end

-- Source: movement.cc. Two thirds of attempted moves use a random
-- offset. A sampled zero offset or blocked cell still spends the turn.
function confusion.move(ctx, player, position, dx, dy)
    if not confusion.active(ctx, player) then
        return dx, dy, false
    end

    if ctx:random("movement", 3) ~= 0 then
        dx = ctx:random("movement", 3) - 1
        dy = ctx:random("movement", 3) - 1
    end

    if dx == 0 and dy == 0 then
        return dx, dy, true
    end

    local x = position.x + dx
    local y = position.y + dy

    return dx, dy, not ctx:walkable(position.level_id, x, y)
end

return confusion
