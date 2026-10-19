local menu = {}

-- Menu letters and close/help keys are decoded once for the terminal routes.
-- Example: menu.letter(27) is "A", matching the 27th displayed option.
function menu.letter(index)
    if index <= 26 then
        return string.char(string.byte("a") + index - 1)
    end

    return string.char(string.byte("A") + index - 27)
end

-- Select by the visible inventory index and then apply a caller's filter;
-- two item menus can share letters while accepting different classes.
-- Example: menu.item({ key = "a", inventory = items }, is_potion).
function menu.item(input, accepted)
    for index, item in ipairs(input.inventory or {}) do
        if input.key == menu.letter(index) and accepted(item) then
            return item
        end
    end

    return nil
end

-- Return a reusable navigation action only for Esc or help. Callers handle
-- nil as a chance to interpret their own menu-specific key bindings.
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
