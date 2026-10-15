local directions = require("policy.input.directions")

local door = {}

function door.route(input)
    if input.key == "esc" then
        return { action = "cancel_door" }
    end

    local direction = directions.command(input.key)

    if direction and direction.kind == 1 then
        return {
            action = "finish_door",
            dx = direction.dx,
            dy = direction.dy,
        }
    end

    return {
        action = "notice",
        text = "Choose a movement direction or Esc to cancel.",
    }
end

return door
