-- Source: spl-transloc.cc:you_teleport and _teleport_player.
local cloud = require("policy.clouds.placement")
local cloud_ids = require("ids.clouds")
local component = require("constants.component")
local translocation = require("policy.scrolls.translocation")
local vision = require("policy.character.vision")
local zap_ids = require("policy.magic.effects.zaps.ids")
local trap_held = require("policy.traps.held")

local teleport = {}
local MAX_ATTEMPTS = 500

local function destination(ctx, player, origin)
    local width, height = ctx:level_size(origin.level_id)

    for _ = 1, MAX_ATTEMPTS do
        local x = ctx:random("teleport", width)
        local y = ctx:random("teleport", height)

        if translocation.can_land(ctx, player, origin.level_id, x, y) and
            not cloud.at(ctx, origin.level_id, x, y) then
            return x, y
        end
    end

    return nil, nil
end

function teleport.toggle(ctx, player)
    local current = ctx:get(player, component.PLAYER_TELEPORT)

    if current and current.remaining_aut > 0 then
        ctx:remove(player, component.PLAYER_TELEPORT)
        ctx:emit("read", "You feel strangely stable.")

        return
    end

    ctx:add(player, component.PLAYER_TELEPORT, {
        remaining_aut = (3 + ctx:random("teleport", 3)) * 10,
    })
    ctx:emit("read", "You feel strangely unstable.")
end

function teleport.tick(ctx, player, aut)
    local current = ctx:get(player, component.PLAYER_TELEPORT)

    if not current or aut <= 0 then
        return
    end

    current.remaining_aut = current.remaining_aut - aut

    if current.remaining_aut > 0 then
        ctx:set(player, component.PLAYER_TELEPORT, current)

        return
    end

    ctx:remove(player, component.PLAYER_TELEPORT)

    teleport.now(ctx, player)
end

function teleport.now(ctx, player)
    local reason = translocation.restriction(ctx, player)

    if reason then
        ctx:emit("read", reason)

        return
    end

    local origin = ctx:get(player, component.POSITION)
    local x, y = destination(ctx, player, origin)

    if not x then
        return
    end

    local message = "Your surroundings suddenly seem different."

    if x == origin.x and y == origin.y then
        message = "Your surroundings flicker for a moment."
    elseif ctx:visible(origin.level_id, origin.x, origin.y,
        vision.radius(ctx, player), x, y) then
        message = "Your surroundings seem slightly different."
    end

    cloud.place(ctx, cloud_ids.CLOUD_TLOC_ENERGY, player,
        origin.level_id, origin.x, origin.y,
        (1 + ctx:random("teleport", 3)) * 10)

    if x ~= origin.x or y ~= origin.y then
        trap_held.release(ctx, player)
        ctx:move_actor(player, origin.level_id, x, y)
    end

    ctx:emit("read", message)
end

function teleport.validate(ctx, player)
    local current = ctx:get(player, component.PLAYER_TELEPORT)

    if current and current.remaining_aut <= 0 then
        error("invalid player teleport delay")
    end
end

return teleport
