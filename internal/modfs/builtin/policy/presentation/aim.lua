local colors = require("policy.presentation.colors")

register.policy({
    id = "presentation.aim",
    run = function(_, input)
        local action = input.throwing and "Throw" or "Fire"
        local verb = input.throwing and "throw" or "fire"

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
    end,
})
