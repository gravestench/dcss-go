-- Xom's temporary trail remembers a single cloud kind on the player. The
-- movement owner leaves ordinary cloud entities behind, so all existing
-- exposure, spread, attribution, and save rules still apply.
local channels = require("constants.message_channels")
local component = require("constants.component")
local cloud_ids = require("ids.clouds")
local placement = require("policy.clouds.placement")
local streams = require("constants.rng_streams")

local trail = {}

local choices = {
    {
        id = cloud_ids.CLOUD_CHAOS,
        weight = 20,
    },

    {
        id = cloud_ids.CLOUD_MAGIC_TRAIL,
        weight = 10,
    },

    {
        id = cloud_ids.CLOUD_MIASMA,
        weight = 5,
    },

    {
        id = cloud_ids.CLOUD_PETRIFY,
        weight = 5,
    },

    {
        id = cloud_ids.CLOUD_MUTAGENIC,
        weight = 5,
    },

    {
        id = cloud_ids.CLOUD_NEGATIVE_ENERGY,
        weight = 5,
    },
}

-- Choose among the source's six cloud kinds with one weighted draw.
-- Storing the chosen ID means later steps spend no kind-selection RNG.
local function choose_kind(ctx, stream)
    local total = 0

    for _, choice in ipairs(choices) do
        total = total + choice.weight
    end

    local draw = ctx:random(stream, total)

    for _, choice in ipairs(choices) do
        if draw < choice.weight then
            return choice.id
        end

        draw = draw - choice.weight
    end

    error("Xom cloud kind draw exhausted")
end

-- Source duration is 600–1200 aut. A second gift replaces the old trail
-- instead of adding another source of clouds to each movement.
function trail.start(ctx, player, stream)
    stream = stream or streams.RELIGION

    local status = {
        remaining_aut = 600 + ctx:random(stream, 601),
        cloud_kind = choose_kind(ctx, stream),
    }

    if ctx:has(player, component.XOM_CLOUD_TRAIL) then
        ctx:set(player, component.XOM_CLOUD_TRAIL, status)
    else
        ctx:add(player, component.XOM_CLOUD_TRAIL, status)
    end

    return status
end

-- Every vacated non-solid cell gets a 3–10 turn cloud. Placement can reject
-- a cell because of stronger clouds or terrain; that is still a real move.
function trail.leave(ctx, player, old_position, stream)
    local status = ctx:get(player, component.XOM_CLOUD_TRAIL)

    if not status or status.remaining_aut <= 0 then
        return false
    end

    stream = stream or streams.RELIGION

    if not ctx:walkable(old_position.level_id,
        old_position.x, old_position.y) then
        return false
    end

    local lifetime = (3 + ctx:random(stream, 8)) * 10
    local cloud = placement.place(ctx, status.cloud_kind, player,
        old_position.level_id, old_position.x, old_position.y, lifetime)

    return cloud ~= nil
end

-- Countdown happens after movement; expiration removes the player status
-- but does not erase clouds already placed on the floor.
function trail.tick(ctx, player, elapsed_aut)
    local status = ctx:get(player, component.XOM_CLOUD_TRAIL)

    if not status or elapsed_aut <= 0 then
        return
    end

    status.remaining_aut = status.remaining_aut - elapsed_aut

    if status.remaining_aut > 0 then
        ctx:set(player, component.XOM_CLOUD_TRAIL, status)

        return
    end

    ctx:remove(player, component.XOM_CLOUD_TRAIL)
    ctx:emit(channels.RELIGION, "Your trail of clouds dissipates.")
end

return trail
