-- Source: item-use.cc:SCR_NOISE uses noisy(25, you.pos()).
local component = require("constants.component")
local item_ids = require("ids.items")
local noise = require("policy.world.noise")
local scrolls = require("policy.scrolls")

local effect = {}
local LOUDNESS = 25

function effect.prepare()
    return nil
end

function effect.apply(ctx, player)
    local position = ctx:get(player, component.POSITION)

    noise.emit(ctx, position, LOUDNESS, player)
    ctx:emit("sound", "You hear a loud clanging noise!")
end

scrolls.register(item_ids.SCR_NOISE, effect)

return effect
