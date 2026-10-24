local menu = require("policy.input.menu")

local selection = {}

-- A generic selection prompt returns the chosen option to its waiting action.
-- Example: selection.route({ key = "a", options = choices }) returns the
-- first option's stable ID without executing the waiting command twice.
function selection.route(input)
    if input.key == "esc" then
        return {
            action = "selection_cancel",
        }
    end

    if input.key == ">" and input.has_next then
        return { action = "selection_next" }
    end

    if input.key == "<" and input.has_previous then
        return { action = "selection_previous" }
    end

    for index, option in ipairs(input.options or {}) do
        if input.key == menu.letter(index) then
            return {
                action = "selection_choose",
                target_id = option.id,
            }
        end
    end

    return {
        action = "notice",
        text = "Choose a letter, use </> for pages, or Esc to cancel.",
    }
end

return selection
