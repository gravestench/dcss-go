-- Xom's three cloud events use the common cloud owner. Fog is an immediate
-- ring, the trail is saved player state, and chaos is one harmful square.
local channels = require("constants.message_channels")
local cloud_ids = require("ids.clouds")
local component = require("constants.component")
local events = require("ids.xom_events")
local fog = require("policy.clouds.fog")
local placement = require("policy.clouds.placement")
local streams = require("constants.rng_streams")
local trail = require("policy.religion.xom.cloud_trail")

local effect = {}

-- Source chaos cloud lasts 3 + three times a 0–11 roll in turns. Its own
-- spread rate is five to fifteen, saved on the resulting cloud entity.
local function chaos(ctx, player, stream)
    local position = ctx:get(player, component.POSITION)

    if placement.at(ctx, position.level_id,
        position.x, position.y) then
        return nil
    end

    local turns = 3 + ctx:random(stream, 12) * 3
    local spread = 5 + ctx:random(stream, 11)

    return placement.place(ctx, cloud_ids.CLOUD_CHAOS, nil,
        position.level_id, position.x, position.y, turns * 10, {
            spread_rate = spread,
        })
end

-- Each event retains its own live effect but shares the cloud entities,
-- so spread and damage remain identical to clouds from other sources.
function effect.apply(ctx, player, event_id, _severity, request)
    local stream = request and request.stream or streams.RELIGION

    if event_id == events.GOOD_FOG then
        local placed = fog.place(ctx, player, stream)

        ctx:emit(channels.RELIGION, "Xom surrounds you with fog!")

        return placed
    end

    if event_id == events.GOOD_CLOUD_TRAIL then
        local status = trail.start(ctx, player, stream)

        ctx:emit(channels.RELIGION,
            "Xom gives your steps a trail of clouds!")

        return status
    end

    if event_id == events.BAD_CHAOS_CLOUD then
        local cloud = chaos(ctx, player, stream)

        if cloud then
            ctx:emit(channels.RELIGION,
                "Xom fills the air around you with chaos!")
        end

        return cloud
    end

    error("cloud effect received another Xom event")
end

return effect
