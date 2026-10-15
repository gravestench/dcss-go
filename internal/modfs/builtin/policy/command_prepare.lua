-- No-time checks and intent preparation for player commands. Action timing,
-- world updates, and equipment completion remain with the command bridge.
local navigation = require("policy.commands.navigation")
local quaff = require("policy.commands.quaff")
local wands = require("policy.inventory.wands")
local items = require("policy.inventory.items")
local equipment = require("policy.inventory.equipment")
local doors = require("policy.inventory.doors")
local projectiles = require("policy.commands.projectiles")
local cast = require("policy.commands.cast")
local abilities = require("policy.commands.abilities")
local spell_learning = require("policy.character.spell_learning")
local confusion = require("policy.magic.player_confusion")
local passwall = require("policy.magic.effects.translocation.passwall")
local rage = require("policy.character.rage")
local vampire = require("policy.character.vampire")
local component = require("constants.component")

local function wait_command(message)
    local decision = {
        intent = {
            kind = 6,
        },
        cost = 10,
    }

    if message then
        decision.events = {
            {
                kind = "status",
                text = message,
            },
        }
    end

    return decision
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

    local petrification = ctx:get(player,
        component.PLAYER_PETRIFICATION)

    if petrification and petrification.petrified_aut > 0 then
        return wait_command("You are petrified!")
    end

    local paralysis = ctx:get(player, "magic.player_paralysis")

    if paralysis and paralysis.remaining_aut > 0 then
        return wait_command("You are paralysed!")
    end

    if ctx:has(player, "magic.passwall_delay") then
        if input.kind == 19 then
            return { message = passwall.cancel(ctx, player) }
        end

        return wait_command()
    end

    local kind = input.kind
    local delay = ctx:get(player, "core.equipment_delay")

    local blood_state = ctx:get(player, component.VAMPIRE)

    if blood_state and blood_state.ritual_remaining_aut > 0 then
        if kind == 19 then
            return { message = vampire.interrupt(ctx, player) }
        end

        if kind ~= 5 then
            return {
                message = "You are performing a blood ritual. Press Esc to stop.",
            }
        end
    end

    local rage_rejection = rage.command_restriction(ctx, player, kind)

    if rage_rejection then
        return { message = rage_rejection }
    end

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

    local learning_state = ctx:get(player, "character.spellcasting")

    if learning_state and learning_state.learning_remaining > 0 then
        if kind == 19 then
            return { message = spell_learning.interrupt(ctx, player) }
        end

        if kind ~= 5 then
            return {
                message = "You are memorising a spell. Press Esc to stop.",
            }
        end
    elseif kind == 19 then
        return { message = "You are not memorising a spell." }
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
        local confused_dx, confused_dy, lost = confusion.move(ctx, player,
            position, dx, dy)

        if lost then
            return wait_command("You're too confused to move!")
        end

        dx = confused_dx
        dy = confused_dy

        return navigation.move(ctx, position, dx, dy)
    elseif kind == 2 or kind == 3 then
        return navigation.stairs(ctx, position, kind == 3)
    elseif kind == 4 then
        return items.prepare_pickup(ctx, player)
    elseif kind == 5 and not delay and
        ctx:has(player, "magic.channel") then
        return {
            intent = { kind = 16 },
            cost = 10,
        }
    elseif kind == 5 or kind == 14 then
        return wait_command()
    elseif kind == 6 then
        return {}
    elseif kind == 7 then
        return quaff.prepare(ctx, player, item_id, input.forced)
    elseif kind == 8 then
        return items.prepare_drop(ctx, player, item_id, input.quantity or 0)
    elseif kind == 9 then
        return equipment.prepare_wield(ctx, player, item_id)
    elseif kind == 10 or kind == 11 then
        return doors.prepare(ctx, player, kind == 10, dx, dy)
    elseif kind == 12 or kind == 13 then
        return equipment.prepare_armour(ctx, player, item_id, kind == 13)
    elseif kind == 16 or kind == 17 then
        return projectiles.prepare(ctx, player, kind == 16, item_id, dx, dy)
    elseif kind == 18 then
        local spell_id = input.spell_id
        local rejection = spell_learning.cannot_begin(ctx, player, spell_id)

        if rejection then
            return { message = rejection }
        end

        return {
            intent = {
                kind = 14,
                spell_id = spell_id,
            },
            cost = 10,
        }
    elseif kind == 20 or kind == 21 then
        return cast.prepare(ctx, player, input)
    elseif kind == 22 then
        return abilities.prepare(ctx, player, input)
    elseif kind == 23 then
        return wands.prepare(ctx, player, item_id, dx, dy)
    end

    return {
        message = "Unknown command.",
    }
end

register.policy({
    id = "command.prepare",
    run = prepare,
})
