local confusion = {}

function confusion.active(ctx, player)
    local state = ctx:get(player, "zap.player_confusion")

    return state ~= nil and state.remaining_aut > 0
end

-- Source: movement.cc:846-900. Two thirds of attempted moves use a random
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
