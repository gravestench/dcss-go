-- Xom's good confusion is a single wave over nearby hostile monsters.
local channels = require("constants.message_channels")
local confusion = require("policy.religion.xom.confusion")
local events = require("ids.xom_events")
local streams = require("constants.rng_streams")

local effect = {}

-- Source good confusion visits nearby hostile monsters in LOS_NO_TRANS.
-- One in twenty is skipped before immunity is checked; a single speech
-- line covers the whole wave instead of one line per target.
local function good_confusion(ctx, player, severity, stream)
    local spoke = false
    local changed = 0

    for _, monster in ipairs(confusion.nearby(ctx, player)) do
        if confusion.hostile(ctx, monster) and
            ctx:random(stream, 20) ~= 0 then
            if not spoke then
                ctx:emit(channels.RELIGION,
                    "Xom confuses the monsters around you!")
                spoke = true
            end

            if confusion.monster(ctx, monster, severity, stream) then
                changed = changed + 1
            end
        end
    end

    return changed
end

-- Bad confusion targets the player and belongs to the status owner.
function effect.apply(ctx, player, event_id, severity, request)
    if event_id ~= events.GOOD_CONFUSION then
        error("confusion effect received another Xom event")
    end

    local stream = request and request.stream or streams.RELIGION

    return good_confusion(ctx, player, severity, stream)
end

return effect
