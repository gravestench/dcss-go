local pregame = {}

function pregame.startup(input)
    if input.key == "z" then
        return {
            action = "screen",
            screen = "drop",
            returnable = false,
        }
    elseif input.key == "x" then
        return {
            action = "step",
            kind = 5,
        }
    end

    return {
        action = "none",
    }
end

return pregame
