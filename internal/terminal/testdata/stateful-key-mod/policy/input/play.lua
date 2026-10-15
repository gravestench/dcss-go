local play = {}

function play.route(input, ctx)
    if input.key == "z" then
        ctx:create()

        return {
            action = "screen",
            screen = "invalid",
            returnable = false,
        }
    end

    return {
        action = "none",
    }
end

return play
