-- The three destruction cards share a postcommit cell prompt. Card play
-- keeps the sampled card while this aim is retried or aborted.
local component = require("constants.component")
local selection_kinds = require("constants.selection_kinds")

local targeted = {}
local SIGHT_RADIUS = 7

-- The source direction chooser accepts a visible direction within LOS.
-- Invalid or missing responses leave the saved card waiting for another aim.
function targeted.aim(ctx, player, request, name)
    local dx = request.dx
    local dy = request.dy
    local position = ctx:get(player, component.POSITION)

    if type(dx) == "number" and type(dy) == "number" and
        dx % 1 == 0 and dy % 1 == 0 and
        (dx ~= 0 or dy ~= 0) and
        math.max(math.abs(dx), math.abs(dy)) <= SIGHT_RADIUS and
        ctx:cell(position.level_id, position.x + dx,
            position.y + dy) and
        ctx:visible(position.level_id, position.x, position.y,
            SIGHT_RADIUS, position.x + dx, position.y + dy) then
        return dx, dy
    end

    return nil, nil, {
        selection = {
            kind = selection_kinds.CELL,
            title = "Aiming: " .. name,
        },
    }
end

-- Source zapping receives one sixth of card power after the target tracer
-- accepts the direction; preserve integer power for the shared zap owners.
function targeted.zap_power(request)
    return math.floor(request.power / 6)
end

return targeted
