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
local nemelex = require("policy.abilities.nemelex")
local card_operations = require("constants.card_operations")
local card_state = require("policy.religion.cards.state")
local ability_ids = require("ids.abilities")

-- Prepare accepted intents before timing; explicit cancellation may still clear an active delay.
local function prepare_raw(ctx, input)
    local player = ctx:player()
    local health = ctx:get(player, "core.health")

    if not health or health.current <= 0 then
        return {
            message = "You die.",
            event_kind = "death",
        }
    end

    -- A sampled card is already spent. Complete its saved prompt before
    -- another command can change the world or consume a second turn.
    local pending_card = card_state.get(ctx, player)

    if pending_card.pending_kind ~= card_operations.NONE and
        (input.kind ~= commands.ability or
            not nemelex.pending_command(ctx, player,
                input.ability_id)) then
        return {
            message = "Finish your pending card action first.",
        }
    end

    -- Free Beogh selection prompts own the command slot until the chosen
    -- action resumes or Esc cancels it. Other actions cannot stale the
    -- selected actor or body while a prompt is saved.
    if ctx:has(player, component.BEOGH_GIFT_CHOICE) and
        (input.kind ~= commands.ability or
            input.ability_id ~= ability_ids.BEOGH_GIFT_ITEM) then
        return { message = "Finish your pending gift choice first." }
    end

    if ctx:has(player, component.BEOGH_RESURRECTION_CHOICE) and
        (input.kind ~= commands.ability or
            input.ability_id ~= ability_ids.BEOGH_RESURRECTION) then
        return { message = "Finish your resurrection choice first." }
    end

    -- The selected blessing item owns the free confirmation slot until
    -- the player confirms or cancels it.
    local weapon_choice = ctx:get(player, component.WEAPON_BLESS_CHOICE)

    if weapon_choice and
        (input.kind ~= commands.ability or
            input.ability_id ~= weapon_choice.ability_id) then
        return { message = "Finish your weapon blessing choice first." }
    end

    -- Involuntary states turn a requested command into a wait before dispatch can spend the chosen action.
    local petrification = ctx:get(player,
        component.PLAYER_PETRIFICATION)

    if petrification and petrification.petrified_aut > 0 then
        return registry.wait("You are petrified!")
    end

    local paralysis = ctx:get(player, "magic.player_paralysis")

    if paralysis and paralysis.remaining_aut > 0 then
        return registry.wait("You are paralysed!")
    end

    local sleep = ctx:get(player, component.PLAYER_SLEEP)

    if sleep and sleep.remaining_aut > 0 then
        return registry.wait("You are asleep!")
    end

    if ctx:has(player, "magic.passwall_delay") then
        if input.kind == commands.cancel_memorise then
            return { message = passwall.cancel(ctx, player) }
        end

        return registry.wait()
    end

    local kind = input.kind
    local delay = ctx:get(player, "core.equipment_delay")

    -- A blood ritual owns the command slot until it finishes or receives its explicit cancel command.
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

    -- Example: a legal move reaches navigation through the registry only after delay and stat gates pass.
    return registry.dispatch(kind, ctx, player, input, position, delay)
end

local module = { run = prepare_raw }

register.policy({
    id = "command.prepare",
    run = module.run,
})

return module
