local play = {}

function play.route(input)
    if input.key == "z" then
        return {
            action = "screen",
            screen = "help",
            returnable = "yes",
        }
    end

    return {
        action = "none",
    }
end

return play
