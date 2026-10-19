-- The z key supplies a string returnable flag where the route contract expects a boolean.

local play = {}

-- Return a malformed flag only for z; ordinary keys stay inert so the test
-- can attribute the route validation failure to this one field.
-- Example: play.route({ key = "z" }).returnable is intentionally a string.
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
