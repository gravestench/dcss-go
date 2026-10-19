local colors = require("policy.presentation.colors")
local registry = require("policy.abilities.registry")

local confirmation = {}

-- The confirmation view displays the pending ability's cost before input resolves it.
-- Example: runtime.Policy("presentation.ability_confirmation",
--     { ability_id = selected_id }) renders the selected ability's prompt.
function confirmation.run(ctx, input)
    local definition = registry.get(input.ability_id)

    if not definition or not definition.confirmation_message then
        error("ability has no confirmation message")
    end

    local message = definition.confirmation_message(ctx, ctx:player())

    return {
        writes = {
            {
                x = 0,
                y = 0,
                text = message,
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
    id = "presentation.ability_confirmation",
    run = confirmation.run,
})

return confirmation
