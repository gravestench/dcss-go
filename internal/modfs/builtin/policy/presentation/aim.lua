local colors = require("policy.presentation.colors")

local aim = {}

-- Aiming draws the current target prompt while input routing retains the pending action.
-- Example: runtime.Policy("presentation.aim", { casting = true, x = 5, y = 7 })
-- shows a casting prompt; the pending target still belongs to input state.
function aim.run(_, input)
    local action = input.casting and "Cast" or
        (input.evoking and "Evoke" or
            (input.throwing and "Throw" or "Fire"))
    local verb = input.casting and "cast" or
        (input.evoking and "evoke" or
            (input.throwing and "throw" or "fire"))

    return {
        writes = {
            {
                x = 0,
                y = 0,
                text = action .. " at " .. input.x .. "," .. input.y ..
                    "  (direction keys, Tab target, Enter " .. verb ..
                    ", Esc cancel)",
                fg = colors.yellow,
            },
        },
    }
end

register.policy({
    id = "presentation.aim",
    run = aim.run,
})

return aim
