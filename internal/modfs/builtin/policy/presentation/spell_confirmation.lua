local colors = require("policy.presentation.colors")

local confirmation = {}

function confirmation.run(_, input)
    if type(input.message) ~= "string" or input.message == "" then
        error("spell confirmation requires a message")
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
    id = "presentation.spell_confirmation",
    run = confirmation.run,
})

return confirmation
