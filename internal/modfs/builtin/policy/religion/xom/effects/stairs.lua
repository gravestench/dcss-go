-- Xom starts stair repulsion and immediately scatters visible linked
-- stairs. Both the timer and each moved stair are part of the saved game.
local channels = require("constants.message_channels")
local events = require("ids.xom_events")
local repel = require("policy.religion.xom.stair_repel")
local streams = require("constants.rng_streams")

local effect = {}

-- The source shuffles all visible stairs once, then tries each even after
-- a previous stair could not move. Fisher-Yates keeps one explicit stream.
local function shuffled(ctx, stairs, stream)
    for index = #stairs, 2, -1 do
        local chosen = ctx:random(stream, index) + 1

        stairs[index], stairs[chosen] = stairs[chosen], stairs[index]
    end

    return stairs
end

-- Setting the status precedes the slide attempts. An unmoving stair still
-- leaves Xom's later movement and climb interference active.
function effect.apply(ctx, player, event_id, _severity, request)
    local climb = event_id == events.BAD_CLIMB_STAIRS

    if not climb and event_id ~= events.BAD_MOVING_STAIRS then
        error("stair effect received another Xom event")
    end

    local stream = request and request.stream or streams.RELIGION
    local nearby = repel.nearby(ctx, player)

    if #nearby == 0 then
        return 0
    end

    repel.start(ctx, player, climb)
    ctx:emit(channels.RELIGION,
        "Xom makes the staircases flee from you!")

    local moved = 0

    for _, stair in ipairs(shuffled(ctx, nearby, stream)) do
        if repel.slide(ctx, player, stair, stream) then
            moved = moved + 1
        end
    end

    return moved
end

return effect
