-- The z key becomes a step action; other keys emit a modded no-binding notice.

local play = {}

-- Remap z to a step and make other keys visibly unbound. The distinct notice
-- proves the terminal used this overlay instead of the bundled keymap.
-- Example: play.route({ key = "z" }).action == "step".
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
