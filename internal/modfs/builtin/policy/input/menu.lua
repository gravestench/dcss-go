local menu = {}

function menu.letter(index)
    if index <= 26 then
        return string.char(string.byte("a") + index - 1)
    end

    return string.char(string.byte("A") + index - 27)
end

function menu.item(input, accepted)
    for index, item in ipairs(input.inventory or {}) do
        if input.key == menu.letter(index) and accepted(item) then
            return item
        end
    end

    return nil
end

function menu.close_or_help(input)
    if input.key == "esc" then
        return {
            action = "screen",
            screen = "play",
            returnable = false,
        }
    end

    if input.key == "?" then
        return {
            action = "screen",
            screen = "help",
            returnable = true,
        }
    end

    return nil
end

return menu
