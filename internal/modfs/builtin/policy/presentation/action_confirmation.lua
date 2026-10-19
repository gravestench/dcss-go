local colors = require("policy.presentation.colors")

local confirmation = {}

-- Dangerous command prompts use the prepared action's message, not a recalculated decision.
-- Example: runtime.Policy("presentation.action_confirmation",
--     { message = "Really attack?" }) renders the pending confirmation.
function confirmation.run(_, input)
    if type(input.message) ~= "string" or input.message == "" then
        error("action confirmation requires a message")
    end

    return {
        writes = {
            {
                x = 0,
                y = 0,
                text = input.message,
                fg = colors.white,
            },
            {
                x = 0,
                y = 2,
                text = "Continue? (y/N)",
                fg = colors.light_grey,
            },
        },
    }
end

register.policy({
    id = "presentation.action_confirmation",
    run = confirmation.run,
})

return confirmation
