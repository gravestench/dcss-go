-- Source: traps.cc:zot_effects[1].
local policy = require("policy.character.stat_loss")
local stats = require("constants.stats")
local streams = require("constants.rng_streams")

local effect = {}

function effect.apply(ctx, player)
    local first = ctx:random(streams.TRAPS, 5)
    local second = ctx:random(streams.TRAPS, 5)
    local amount = 1 + math.floor((first + second) / 2)
    local field = stats.ORDER[ctx:random(streams.TRAPS, #stats.ORDER) + 1]

    policy.drain(ctx, player, field, amount)
    ctx:emit("trap", "You feel your strength ebb away.")
end

return effect
