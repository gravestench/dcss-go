local commands = require("policy.input.commands")

local session = {}

local stats = {
    S = "str",
    I = "int",
    D = "dex",
}

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

return session
