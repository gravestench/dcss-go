-- Xom's banishment uses the ordinary Abyss state and return-site owner.
-- A pseudo banishment really visits the Abyss before being undone.
local channels = require("constants.message_channels")
local component = require("constants.component")
local events = require("ids.xom_events")
local streams = require("constants.rng_streams")
local abyss = require("policy.world.abyss")

local effect = {}

-- Source banishment scales Abyss depth by experience level. Keeping the
-- outside origin in the shared banishment component makes a later save
-- and escape behave the same as a non-Xom banishment.
function effect.apply(ctx, player, event_id, _severity, request)
    if event_id ~= events.BAD_BANISHMENT and
        event_id ~= events.BAD_PSEUDO_BANISHMENT then
        error("travel effect received another Xom event")
    end

    local progress = ctx:get(player, component.PROGRESSION)
    local stream = request and request.stream or streams.RELIGION

    ctx:emit(channels.RELIGION, "Xom banishes you to the Abyss!")
    abyss.banish(ctx, player, {
        power = progress and progress.level or 1,
        stream = stream,
    })

    if event_id == events.BAD_PSEUDO_BANISHMENT then
        ctx:emit(channels.RELIGION,
            "Xom abruptly takes back the banishment!")
        abyss.escape(ctx, player)
    end

    return event_id
end

return effect
