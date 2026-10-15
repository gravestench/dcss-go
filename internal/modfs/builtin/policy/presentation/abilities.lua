local colors = require("policy.presentation.colors")
local menu = require("policy.input.menu")
local registry = require("policy.abilities.registry")

local abilities = {}

local function write(writes, x, y, value, color)
    writes[#writes + 1] = {
        x = x,
        y = y,
        text = value,
        fg = color,
    }
end

function abilities.run(ctx, input)
    local options = registry.available(ctx, ctx:player())
    local writes = {}

    write(writes, 0, 0, "Use which ability?", colors.white)
    write(writes, 0, 1, "        Ability                    Range",
        colors.light_blue)

    for index, option in ipairs(options) do
        local y = index + 2

        if y >= input.height - 2 then
            break
        end

        local label = string.format("  %s - %-25.25s %5d",
            menu.letter(index), option.name, option.range)

        write(writes, 0, y, label, colors.light_grey)
    end

    if #options == 0 then
        write(writes, 0, 3, "You have no abilities.", colors.brown)
    end

    write(writes, 0, input.height - 2,
        "Esc - Cancel    ? - Help", colors.brown)

    return {
        writes = writes,
        options = options,
    }
end

register.policy({
    id = "presentation.abilities",
    run = abilities.run,
})

return abilities
