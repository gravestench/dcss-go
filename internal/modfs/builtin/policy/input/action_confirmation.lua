local confirmation = {}

-- This route resumes a prepared action only after the player answers the pending prompt.
-- Example: confirmation.route({ key = "y" }).action accepts the action;
-- an unrecognized key keeps the same prompt open with a notice.
function confirmation.route(input)
    if input.key == "y" then
        return { action = "action_confirm_accept" }
    end

    if input.key == "n" or input.key == "esc" or
        input.key == "enter" then
        return { action = "action_confirm_cancel" }
    end

    return {
        action = "notice",
        text = "Answer y or n.",
    }
end

return confirmation
