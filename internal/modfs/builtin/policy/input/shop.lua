local shop = {}

-- Resolve the displayed stock letter to its current item ID; sorted stock
-- can move rows without changing what a selected letter means on this frame.
local function selected(input, key)
    for _, item in ipairs(input.items or {}) do
        if item.letter == key then
            return item.id
        end
    end

    return nil
end

-- Shop input chooses stock and confirms purchase against the current visible shop list.
-- Example: shop.route(nil, { key = "enter", items = stock }) requests
-- confirmation; the purchase itself waits for a later explicit answer.
function shop.route(_, input)
    local key = input.key

    if input.confirming then
        if key == "y" or key == "Y" or key == "enter" then
            return { action = "buy" }
        end

        return { action = "cancel_confirm" }
    end

    if key == "esc" or key == "<" then
        return { action = "close" }
    elseif key == "enter" then
        return { action = "confirm" }
    elseif key == "!" then
        return { action = "sort" }
    elseif key == "$" then
        return { action = "list" }
    elseif key == "x" then
        return { action = "examine" }
    elseif key == "space" then
        return { action = "toggle_focus" }
    elseif key == "up" or key == "down" then
        return { action = "focus", delta = key == "up" and -1 or 1 }
    elseif key == "?" then
        return { action = "help" }
    end

    local id = selected(input, key)

    if id then
        return { action = "toggle", id = id }
    end

    return { action = "none" }
end

register.policy({
    id = "terminal.shop_input",
    run = shop.route,
})

return shop
