local commands = require("policy.input.commands")

local session = {}

local stats = {
    S = "str",
    I = "int",
    D = "dex",
}

-- Delayed actions and stat choices resume from session state rather than reconstructing an earlier command.
function session.stat(input)
    local id = stats[input.key]

    if id then
        return {
            action = "choose_stat",
            id = id,
        }
    end

    return {
        action = "notice",
        text = "Choose S, I, or D.",
    }
end

-- Example: S accepts only a save confirmation; unrelated confirmation screens wait for y/Y.
-- Interpret the key in its current confirmation context, preventing the
-- save shortcut from accepting unrelated irreversible menu choices.
function session.confirm(input)
    local key = input.key

    if key == "esc" or key == "n" or key == "N" then
        return { action = "confirm_cancel" }
    end

    if key == "y" or key == "Y" or
        (key == "S" and input.confirmation == "save") then
        return { action = "confirm_accept" }
    end

    return { action = "none" }
end

-- The delay route resumes the stored equipment action after time advances.
function session.equipment_delay(input)
    if input.key == "esc" then
        return {
            action = "cancel_equipment",
            kind = commands.cancel_equipment,
        }
    end

    if input.key == "S" then
        return {
            action = "confirm",
            confirmation = "save",
            interrupt_tick = true,
        }
    end

    if input.key == "ctrl+s" then
        return {
            action = "save_exit",
            interrupt_tick = true,
        }
    end

    return {
        action = "notice",
        text = "You are changing your equipment. Esc interrupts.",
    }
end

-- Memorisation permits save and cancellation while the unfinished spell remains in session state.
function session.memorisation_delay(input)
    if input.key == "esc" then
        return {
            action = "cancel_memorise",
            kind = commands.cancel_memorise,
        }
    end

    if input.key == "S" then
        return {
            action = "confirm",
            confirmation = "save",
            interrupt_tick = true,
        }
    end

    if input.key == "ctrl+s" then
        return {
            action = "save_exit",
            interrupt_tick = true,
        }
    end

    return {
        action = "notice",
        text = "You are memorising a spell. Esc interrupts.",
    }
end

-- Use the same save/cancel controls during a blood ritual as during other
-- persisted delays, while leaving the unfinished ritual in session state.
function session.vampire_delay(input)
    if input.key == "esc" then
        return {
            action = "cancel_vampire",
            kind = commands.cancel_vampire,
        }
    end

    if input.key == "S" then
        return {
            action = "confirm",
            confirmation = "save",
            interrupt_tick = true,
        }
    end

    if input.key == "ctrl+s" then
        return {
            action = "save_exit",
            interrupt_tick = true,
        }
    end

    return {
        action = "notice",
        text = "You are performing a blood ritual. Esc interrupts.",
    }
end

return session
