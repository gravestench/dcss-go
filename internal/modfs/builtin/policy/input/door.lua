local directions = require("policy.input.directions")

local door = {}

-- The door prompt resolves one selected adjacent feature into the pending door command.
-- Example: door.route({ key = "h" }) returns a direction; it does not open
-- the door yet, so the prepared command can validate its target first.
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
