local colors = require("policy.presentation.colors")

local aim = {}

function aim.run(_, input)
    local action = input.casting and "Cast" or
        (input.throwing and "Throw" or "Fire")
    local verb = input.casting and "cast" or
        (input.throwing and "throw" or "fire")

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
