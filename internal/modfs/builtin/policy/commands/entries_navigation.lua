local commands = require("policy.input.commands")
local confusion = require("policy.magic.player_confusion")
local fear = require("policy.character.player_fear")
local mesmerism = require("policy.character.player_mesmerism")
local doors = require("policy.inventory.doors")
local items = require("policy.inventory.items")
local navigation = require("policy.commands.navigation")
local registry = require("policy.commands.registry")
local intent = require("constants.intent")
local streams = require("constants.rng_streams")
local display = require("policy.combat.monster_support.display")
local terrain = require("constants.terrain")

local entries = {}

-- Navigation entries route terrain actions and delayed equipment continuation through the same dispatcher.
-- Example: entries.move(ctx, player, { dx = 1, dy = 0 }, position) prepares an eastward step.
function entries.move(ctx, player, input, position)
    local dx, dy, lost = confusion.move(ctx, player, position,
        input.dx or 0, input.dy or 0)

    if lost then
        return registry.wait("You're too confused to move!")
    end

    -- Fear and mesmerism do not constrain a confused step. An ordinary
    -- threatened step is refused before spending aut; attacking a feared
    -- neighbor can instead flinch on the melee stream.
    if not confusion.active(ctx, player) then
        local destination = {
            level_id = position.level_id,
            x = position.x + dx,
            y = position.y + dy,
        }
        local target = ctx:actor_at(destination.level_id,
            destination.x, destination.y)

        if target and fear.afraid_of(ctx, player, target) and
            ctx:random(streams.MELEE, 3) == 0 then
            return {
                message = "You attempt to attack the " ..
                    display.name(ctx, target) ..
                    ", but flinch away in fear!",
            }
        end

        if not target then
            local beholder = mesmerism.blocked(ctx, player,
                position, destination)

            if beholder then
                return {
                    message = "You cannot move away from the " ..
                        display.name(ctx, beholder) .. "!",
                }
            end

            local source = fear.blocked(ctx, player,
                position, destination)

            if source then
                return {
                    message = "You cannot move closer to the " ..
                        display.name(ctx, source) .. "!",
                }
            end
        end
    end

    return navigation.move(ctx, position, dx, dy)
end

-- Match an upstairs link at the current cell before changing floors.
function entries.upstairs(ctx, player, input, position)
    local beholder = mesmerism.any(ctx, player)

    if beholder and ctx:cell(position.level_id,
        position.x, position.y) ~= terrain.DNGN_TRANSPORTER then
        return {
            message = "You cannot leave while mesmerised by the " ..
                display.name(ctx, beholder) .. "!",
        }
    end

    return navigation.stairs(ctx, position, false, player, input.forced)
end

-- Match a downstairs link at the current cell before changing floors.
function entries.downstairs(ctx, player, input, position)
    local beholder = mesmerism.any(ctx, player)

    if beholder and ctx:cell(position.level_id,
        position.x, position.y) ~= terrain.DNGN_TRANSPORTER then
        return {
            message = "You cannot leave while mesmerised by the " ..
                display.name(ctx, beholder) .. "!",
        }
    end

    return navigation.stairs(ctx, position, true, player, input.forced)
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
