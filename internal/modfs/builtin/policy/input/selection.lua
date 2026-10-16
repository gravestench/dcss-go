local menu = require("policy.input.menu")

local selection = {}

function selection.route(input)
    if input.key == "esc" then
        return {
            action = "selection_cancel",
        }
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
        text = "Choose an option by its letter, or Esc to cancel.",
    }
end

return selection
