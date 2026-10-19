local commands = require("policy.input.commands")
local confusion = require("policy.magic.player_confusion")
local doors = require("policy.inventory.doors")
local items = require("policy.inventory.items")
local navigation = require("policy.commands.navigation")
local registry = require("policy.commands.registry")
local intent = require("constants.intent")

local entries = {}

-- Navigation entries route terrain actions and delayed equipment continuation through the same dispatcher.
-- Example: entries.move(ctx, player, { dx = 1, dy = 0 }, position) prepares an eastward step.
function entries.move(ctx, player, input, position)
    local dx, dy, lost = confusion.move(ctx, player, position,
        input.dx or 0, input.dy or 0)

    if lost then
        return registry.wait("You're too confused to move!")
    end

    return navigation.move(ctx, position, dx, dy)
end

-- Match an upstairs link at the current cell before changing floors.
function entries.upstairs(ctx, _, _, position)
    return navigation.stairs(ctx, position, false)
end

-- Match a downstairs link at the current cell before changing floors.
function entries.downstairs(ctx, _, _, position)
    return navigation.stairs(ctx, position, true)
end

-- Select floor items before charging pickup time or changing inventory.
function entries.pickup(ctx, player, input)
    return items.prepare_pickup(ctx, player, input.pending_vault_item)
end

-- Channelled waiting costs ten aut; ordinary waiting carries an explicit marker for timing.
function entries.wait(ctx, player, _, _, delay)
    if not delay and ctx:has(player, "magic.channel") then
        return {
            intent = {
                kind = intent.CHANNEL_WAIT,
            },
            cost = 10,
            explicit_wait = true,
        }
    end

    local decision = registry.wait()
    decision.explicit_wait = true

    return decision
end

-- Inspection returns without an action cost because it cannot change world state.
function entries.inspect()
    return {}
end

-- Continue an existing equipment delay without preparing a second change.
function entries.continue_equipment()
    return registry.wait()
end

-- Check the target door before emitting a timed open action.
function entries.open_door(ctx, player, input)
    return doors.prepare(ctx, player, true, input.dx or 0, input.dy or 0)
end

-- Check the target door before emitting a timed close action.
function entries.close_door(ctx, player, input)
    return doors.prepare(ctx, player, false, input.dx or 0, input.dy or 0)
end

registry.register(commands.move, entries.move)
registry.register(commands.upstairs, entries.upstairs)
registry.register(commands.downstairs, entries.downstairs)
registry.register(commands.pickup, entries.pickup)
registry.register(commands.wait, entries.wait)
registry.register(commands.continue_equipment, entries.continue_equipment)
registry.register(commands.inspect, entries.inspect)
registry.register(commands.open_door, entries.open_door)
registry.register(commands.close_door, entries.close_door)

return entries
