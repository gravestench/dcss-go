-- Source: traps.cc. Blink visible monsters and the triggering actor.
local catalog = require("policy.catalog")
local component = require("constants.component")
local blink = require("policy.combat.dispersal")
local streams = require("constants.rng_streams")
local teleport = require("policy.magic.effects.zaps.teleport_other")
local translocation = require("policy.scrolls.translocation")
local vision = require("policy.character.vision")
local held = require("policy.traps.held")

local effect = {}

-- Find an open nearby cell with trap RNG before changing the player's position.
local function player_blink(ctx, player)
    local position = ctx:get(player, component.POSITION)

    for _ = 1, 150 do
        local x = position.x + ctx:random(streams.TRAPS, 13) - 6
        local y = position.y + ctx:random(streams.TRAPS, 13) - 6

        if translocation.can_blink(ctx, player, position, x, y) then
            held.release(ctx, player)
            ctx:move_actor(player, position.level_id, x, y)
            ctx:emit("trap", "You blink.")

            return
        end
    end
end

-- Blink eligible actors visible from the trap cell, then handle the triggering actor separately.
-- Example: effect.trigger(ctx, nil, player, site) blinks the player and nearby actors.
function effect.trigger(ctx, _, actor, site)
    local player = ctx:player()
    local player_position = ctx:get(player, component.POSITION)
    local radius = vision.radius(ctx, player)

    if actor == player then
        ctx:emit("trap", "You enter a dispersal trap!")
    end

    for _, monster in ipairs(ctx:query({ component.ACTOR, component.AI })) do
        local position = ctx:get(monster, component.POSITION)
        local state = ctx:get(monster, component.ACTOR)

        if position and position.level_id == site.level_id and
            ctx:visible(site.level_id, site.x, site.y, radius,
                position.x, position.y) then
            local definition = catalog.get("monsters", state.kind_id)

            if not teleport.no_tele(state, definition, ctx, monster) then
                blink.blink(ctx, player, monster, definition)
            end
        end
    end

    if actor == player or player_position and
        player_position.level_id == site.level_id and
        ctx:visible(site.level_id, site.x, site.y, radius,
            player_position.x, player_position.y) then
        player_blink(ctx, player)
    end
end

return effect
