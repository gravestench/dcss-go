-- Source: item-use.cc:SCR_BLINKING and spl-transloc.cc:controlled_blink.
local cloud = require("policy.clouds.placement")
local cloud_ids = require("ids.clouds")
local component = require("constants.component")
local item_ids = require("ids.items")
local movement = require("policy.abilities.movement")
local scrolls = require("policy.scrolls")
local translocation = require("policy.scrolls.translocation")
local zap_ids = require("policy.magic.effects.zaps.ids")

local effect = {}

-- Example: Blink rejects a target that fails the shared translocation landing check.
-- Known restrictions fail early; otherwise request a cell and validate range, sight, and landing.
function effect.prepare(ctx, player, request)
    local reason = translocation.restriction(ctx, player)

    if reason then
        if request.known then
            return {
                message = reason,
            }
        end

        return nil
    end

    if request.cancelled then
        if request.known then
            return {
                message = "Okay.",
            }
        end

        return nil
    end

    if request.dx == 0 and request.dy == 0 then
        return {
            selection = {
                kind = "cell",
                title = "Blink to where?",
            },
        }
    end

    local position = ctx:get(player, component.POSITION)
    local x = position.x + request.dx
    local y = position.y + request.dy

    if not translocation.can_blink(ctx, player, position, x, y) then
        return {
            message = "You cannot blink there.",
        }
    end

    return nil
end

-- Recheck translocation at execution, escape grasp, leave a cloud, then move to the chosen cell.
function effect.apply(ctx, player, request)
    local reason = translocation.restriction(ctx, player)

    if reason then
        ctx:emit("read", reason)

        return
    end

    if not movement.escape_grasp(ctx, player, 2) then
        return
    end

    local origin = ctx:get(player, component.POSITION)
    local x = origin.x + request.dx
    local y = origin.y + request.dy

    cloud.place(ctx, cloud_ids.CLOUD_TLOC_ENERGY, player,
        origin.level_id, origin.x, origin.y,
        (1 + ctx:random("teleport", 3)) * 10)
    ctx:move_actor(player, origin.level_id, x, y)
    ctx:emit("read", "You blink.")
end

scrolls.register(item_ids.SCR_BLINKING, effect)

return effect
