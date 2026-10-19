local directions = require("policy.input.directions")

local aim = {}

-- Aiming input fills the pending target request without invoking the command a second time.
-- Example: aim.route({ key = "tab", casting = true }) cycles targets while
-- the prepared spell and its resource cost stay owned by the pending action.
function aim.route(input)
    if input.key == "esc" then
        if input.reading then
            return {
                action = "cancel_read_aim",
            }
        end

        return {
            action = "screen",
            screen = "play",
            returnable = false,
        }
    end

    if input.key == "enter" then
        return { action = "fire_aim" }
    end

    if input.key == "tab" then
        return { action = "cycle_aim" }
    end

    local direction = directions.command(input.key)

    if direction and direction.kind == 1 then
        return {
            action = "move_aim",
            dx = direction.dx,
            dy = direction.dy,
        }
    end

    return {
        action = "notice",
        text = "Move the target with direction keys; Enter " ..
            (input.casting and "casts" or
                (input.evoking and "evokes" or "fires")) ..
            ", Esc cancels.",
    }
end

return aim
