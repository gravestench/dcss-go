-- Xom rides the ordinary immediate-teleport owner for several stops.
-- His good and bad journeys differ only in when danger ends the ride.
local channels = require("constants.message_channels")
local events = require("ids.xom_events")
local teleport = require("policy.magic.player_teleport")
local streams = require("constants.rng_streams")
local tension = require("policy.combat.monster_seal_tension")

local effect = {}

-- A positive source tension means the current landing is dangerous to
-- the player. Query it after each teleport, since the player has moved.
local function dangerous(ctx, player)
    return tension.current(ctx, player) > 0
end

-- The good train prefers a quiet final stop: its three-in-four chance
-- continues regardless, and danger forces another stop when that fails.
local function good(ctx, player, stream)
    local count = 0

    while true do
        count = count + 1
        teleport.now(ctx, player, {
            channel = channels.RELIGION,
        })

        if ctx:random(stream, 10) == 0 or
            count >= 7 + ctx:random(stream, 5) then
            break
        end

        if ctx:random(stream, 4) >= 3 and
            not dangerous(ctx, player) then
            break
        end
    end

    return count
end

-- The bad train seeks a dangerous final stop. It tests the length cap
-- before its continuation chance, preserving source RNG order.
local function bad(ctx, player, stream)
    local count = 0

    while true do
        teleport.now(ctx, player, {
            channel = channels.RELIGION,
        })

        local before = count
        count = count + 1

        if before >= 7 + ctx:random(stream, 5) or
            ctx:random(stream, 4) >= 3 or
            dangerous(ctx, player) then
            break
        end
    end

    return count
end

-- Both events use the same live movement, clouds, traps, and save owner.
function effect.apply(ctx, player, event_id, _severity, request)
    local stream = request and request.stream or streams.RELIGION

    ctx:emit(channels.RELIGION,
        "Xom takes you on a teleportation journey!")

    if event_id == events.GOOD_TELEPORT then
        return good(ctx, player, stream)
    end

    if event_id == events.BAD_TELEPORT then
        return bad(ctx, player, stream)
    end

    error("teleport effect received another Xom event")
end

return effect
