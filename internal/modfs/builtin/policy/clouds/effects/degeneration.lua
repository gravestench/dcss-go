-- cloud.cc:CLOUD_DEGENERATION drains a random player attribute 1/4 of ticks.
local streams = require("constants.rng_streams")
local stats = require("constants.stats")
local loss = require("policy.character.stat_loss")

local degeneration = {}

function degeneration.apply(ctx, actor)
    if actor ~= ctx:player() or
        ctx:random(streams.CLOUDS, 4) ~= 0 then
        return 0
    end

    local index = ctx:random(streams.CLOUDS, #stats.ORDER) + 1
    local amount = 1 + math.floor((
        ctx:random(streams.CLOUDS, 4) +
        ctx:random(streams.CLOUDS, 4)) / 2)

    loss.drain(ctx, actor, stats.ORDER[index], amount)
    ctx:emit("cloud", "You feel yourself deteriorate.")

    return 0
end

return degeneration
