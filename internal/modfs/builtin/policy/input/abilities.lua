local commands = require("policy.input.commands")
local menu = require("policy.input.menu")

local abilities = {}

function abilities.route(input)
    local navigation = menu.close_or_help(input)

    if navigation then
        return navigation
    end

    for index, option in ipairs(input.options or {}) do
        if input.key == menu.letter(index) then
            if option.range > 0 then
                return {
                    action = "aim",
                    kind = commands.ability,
                    ability_id = option.id,
                }
            end

            if option.confirmation_needed then
                return {
                    action = "confirm_ability",
                    ability_id = option.id,
                }
            end

            return {
                action = "ability_step",
                ability_id = option.id,
            }
        end
    end

    return {
        action = "notice",
        text = "Choose an ability.",
    }
end

function abilities.confirm(input)
    if input.key == "y" then
        return { action = "ability_confirm_accept" }
    end

    if input.key == "n" or input.key == "esc" or
        input.key == "enter" then
        return {
            action = "screen",
            screen = "abilities",
            returnable = false,
        }
    end

    return {
        action = "notice",
        text = "Answer y or n.",
    }
end

return abilities
