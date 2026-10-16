-- No-time checks and intent preparation for player commands. Action timing,
-- world updates, and equipment completion remain with the command bridge.
local equipment = require("policy.inventory.equipment")
local spell_learning = require("policy.character.spell_learning")
local passwall = require("policy.magic.effects.translocation.passwall")
local rage = require("policy.character.rage")
local vampire = require("policy.character.vampire")
local component = require("constants.component")
local commands = require("policy.input.commands")
local registry = require("policy.commands.registry")

local function prepare_raw(ctx, input)
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
        return registry.wait("You are petrified!")
    end

    local paralysis = ctx:get(player, "magic.player_paralysis")

    if paralysis and paralysis.remaining_aut > 0 then
        return registry.wait("You are paralysed!")
    end

    if ctx:has(player, "magic.passwall_delay") then
        if input.kind == commands.cancel_memorise then
            return { message = passwall.cancel(ctx, player) }
        end

        return registry.wait()
    end

    local kind = input.kind
    local delay = ctx:get(player, "core.equipment_delay")

    local blood_state = ctx:get(player, component.VAMPIRE)

    if blood_state and blood_state.ritual_remaining_aut > 0 then
        if kind == commands.cancel_vampire then
            return { message = vampire.interrupt(ctx, player) }
        end

        if kind ~= commands.wait then
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
        if kind == commands.cancel_equipment then
            return {
                message = equipment.cancel(ctx, player),
            }
        end

        if kind ~= commands.inspect and
            kind ~= commands.continue_equipment then
            return {
                message = "You are changing your equipment. Press Esc to stop.",
            }
        end
    elseif kind == commands.continue_equipment or
        kind == commands.cancel_equipment then
        return {
            message = "You are not changing your equipment.",
        }
    end

    local learning_state = ctx:get(player, "character.spellcasting")

    if learning_state and learning_state.learning_remaining > 0 then
        if kind == commands.cancel_memorise then
            return { message = spell_learning.interrupt(ctx, player) }
        end

        if kind ~= commands.wait then
            return {
                message = "You are memorising a spell. Press Esc to stop.",
            }
        end
    elseif kind == commands.cancel_memorise then
        return { message = "You are not memorising a spell." }
    end

    local progress = ctx:get(player, "core.progression")

    if progress and progress.pending_stat_level ~= 0 and
        kind ~= commands.inspect then
        return {
            message = "Choose Strength, Intelligence, or Dexterity first.",
        }
    end

    local position = ctx:get(player, "core.position")

    if not position then
        error("player " .. ctx:id(player) .. " has no position")
    end

    return registry.dispatch(kind, ctx, player, input, position, delay)
end

local module = { run = prepare_raw }

register.policy({
    id = "command.prepare",
    run = module.run,
})

return module
