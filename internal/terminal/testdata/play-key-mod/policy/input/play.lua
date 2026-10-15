local play = {}

function play.route(input)
        if input.key == "z" then
            return {
                action = "step",
                kind = 5,
            }
        end

        return {
            action = "notice",
            text = "Modded keymap has no binding for this key.",
        }
end

return play
