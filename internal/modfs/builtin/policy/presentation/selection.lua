local colors = require("policy.presentation.colors")
local menu = require("policy.input.menu")

local selection = {}

-- The generic selection view renders options in the same order the input route indexes them.
-- Example: selection.run(nil, { title = "Pick one", options = choices, height = 24 })
-- writes letters by option index, so the next key resolves the shown choice.
function selection.run(_, input)
    local writes = {
        {
            x = 0,
            y = 0,
            text = input.title,
            fg = colors.white,
        },
    }

    for index, option in ipairs(input.options) do
        writes[#writes + 1] = {
            x = 1,
            y = index + 1,
            text = menu.letter(index) .. " - " .. option.label,
            fg = colors.light_grey,
        }
    end

    writes[#writes + 1] = {
        x = 0,
        y = input.height - 2,
            text = "Page " .. input.page .. "/" .. input.pages ..
                "  < Previous  > Next  Esc Cancel",
        fg = colors.brown,
    }

    return {
        writes = writes,
    }
end

register.policy({
    id = "presentation.selection",
    run = selection.run,
})

return selection
