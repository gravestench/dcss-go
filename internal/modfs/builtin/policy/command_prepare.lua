-- No-time checks and intent preparation for player commands. Action timing,
-- world updates, and equipment completion remain with the command bridge.
local navigation = require("policy.commands.navigation")
local quaff = require("policy.commands.quaff")
local items = require("policy.inventory.items")
local equipment = require("policy.inventory.equipment")
local doors = require("policy.inventory.doors")

local function wait_command()
    return {
        intent = {
            kind = 6,
        },
        cost = 10,
    }
end

local function prepare(ctx, input)
    local player = ctx:player()
    local health = ctx:get(player, "core.health")

    if not health or health.current <= 0 then
        return {
            message = "You die.",
            event_kind = "death",
        }
    end

    local kind = input.kind
    local delay = ctx:get(player, "core.equipment_delay")

    if delay then
        if kind == 15 then
            return {
                message = equipment.cancel(ctx, player),
            }
        end

        if kind ~= 6 and kind ~= 14 then
            return {
                message = "You are changing your equipment. Press Esc to stop.",
            }
        end
    elseif kind == 14 or kind == 15 then
        return {
            message = "You are not changing your equipment.",
        }
    end

    local progress = ctx:get(player, "core.progression")

    if progress and progress.pending_stat_level ~= 0 and kind ~= 6 then
        return {
            message = "Choose Strength, Intelligence, or Dexterity first.",
        }
    end

    local position = ctx:get(player, "core.position")

    if not position then
        error("player " .. ctx:id(player) .. " has no position")
    end

    local dx = input.dx or 0
    local dy = input.dy or 0
    local item_id = input.item_id or 0

    if kind == 1 then
        return navigation.move(ctx, position, dx, dy)
    elseif kind == 2 or kind == 3 then
        return navigation.stairs(ctx, position, kind == 3)
    elseif kind == 4 then
        return items.prepare_pickup(ctx, player)
    elseif kind == 5 or kind == 14 then
        return wait_command()
    elseif kind == 6 then
        return {}
    elseif kind == 7 then
        return quaff.prepare(ctx, player, item_id)
    elseif kind == 8 then
        return items.prepare_drop(ctx, player, item_id, input.quantity or 0)
    elseif kind == 9 then
        return equipment.prepare_wield(ctx, player, item_id)
    elseif kind == 10 or kind == 11 then
        return doors.prepare(ctx, player, kind == 10, dx, dy)
    elseif kind == 12 or kind == 13 then
        return equipment.prepare_armour(ctx, player, item_id, kind == 13)
    end

    return {
        message = "Unknown command.",
    }
end

register.policy({
    id = "command.prepare",
    run = prepare,
})
