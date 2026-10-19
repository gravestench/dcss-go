local modal = {}

-- Modal, help, and death screens consume input without creating a gameplay command.
-- Example: modal.route({ key = "?" }) opens help as a returnable screen.
function modal.route(input)
    if input.key == "esc" then
        return {
            action = "screen",
            screen = "play",
            returnable = false,
        }
    end

    if input.key == "?" then
        return {
            action = "screen",
            screen = "help",
            returnable = true,
        }
    end

    return {
        action = "notice",
        text = "This menu control is unavailable in the Go port.",
    }
end

-- Esc returns to the screen that opened help, preserving its pending state;
-- other unimplemented controls explain themselves instead of advancing time.
function modal.help(input)
    if input.key == "esc" then
        return { action = "return_screen" }
    end

    return {
        action = "notice",
        text = "This help control is unavailable in the Go port.",
    }
end

-- Death-screen acknowledgement returns to startup without issuing any
-- player action, because the old session has already ended.
function modal.death(input)
    if input.key == "esc" or input.key == "enter" then
        return { action = "return_to_startup" }
    end

    return { action = "none" }
end

return modal
