-- Source: item-use.cc:SCR_TELEPORTATION calls you_teleport.
local item_ids = require("ids.items")
local scrolls = require("policy.scrolls")
local teleport = require("policy.magic.player_teleport")
local translocation = require("policy.scrolls.translocation")

local effect = {}

function effect.prepare(ctx, player, request)
    local reason = translocation.restriction(ctx, player)

    if reason and request.known then
        return {
            message = reason,
        }
    end

    return nil
end

function effect.apply(ctx, player)
    local reason = translocation.restriction(ctx, player)

    if reason then
        ctx:emit("read", reason)

        return
    end

    teleport.toggle(ctx, player)
end

scrolls.register(item_ids.SCR_TELEPORTATION, effect)

return effect
