local modal = {}

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

function modal.help(input)
    if input.key == "esc" then
        return { action = "return_screen" }
    end

    return {
        action = "notice",
        text = "This help control is unavailable in the Go port.",
    }
end

function modal.death(input)
    if input.key == "esc" or input.key == "enter" then
        return { action = "return_to_startup" }
    end

    return { action = "none" }
end

return modal
