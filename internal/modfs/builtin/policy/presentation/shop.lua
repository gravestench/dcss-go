local colors = require("policy.presentation.colors")

local shop = {}

local function write(writes, x, y, text, color)
    writes[#writes + 1] = {
        x = x,
        y = y,
        text = text,
        fg = color,
    }
end

local function item_color(item, gold, selected_total)
    if item.selected and selected_total > gold then
        return colors.light_red
    elseif item.selected then
        return colors.light_green
    elseif item.on_list then
        return colors.light_cyan
    elseif item.price > gold then
        return colors.red
    end

    return colors.light_grey
end

function shop.rows(_, input)
    local writes = {}
    local items = input.items or {}
    local selected_total = input.selected_total or 0
    local height = input.height
    local focus = input.focus or 1
    local visible = math.max(1, height - 7)
    local first = math.max(1, focus - visible + 1)

    write(writes, 0, 0, input.name, colors.yellow)
    write(writes, 0, 1, "Gold: " .. input.gold, colors.light_grey)
    write(writes, 20, 1, "Sort: " .. input.sort, colors.brown)

    if #items == 0 then
        write(writes, 1, 3, "This shop is empty.", colors.brown)
    end

    for index = first, math.min(#items, first + visible - 1) do
        local item = items[index]
        local marker = item.selected and "+" or item.on_list and "$" or "-"
        local label = item.name

        if item.quantity > 1 then
            label = item.quantity .. " " .. label
        end

        local row = string.format(" %s %s %5d gold   %s",
            item.letter, marker, item.price, label)
        local color = item_color(item, input.gold, selected_total)

        write(writes, 0, index - first + 3, row, color)
    end

    if input.confirming then
        write(writes, 0, height - 4,
            "Purchase selected items for " .. selected_total .. " gold? (y/n)",
            colors.yellow)
    else
        write(writes, 0, height - 4,
            "Select letters or Space, Enter buys, ! sort, $ list, x examine",
            colors.brown)
    end

    write(writes, 0, height - 3,
        "Esc - Leave shop    Arrow keys - Browse    ? - Help", colors.brown)

    if input.notice and input.notice ~= "" then
        write(writes, 0, height - 2, input.notice, colors.light_grey)
    end

    return { writes = writes }
end

register.policy({
    id = "presentation.shop",
    run = shop.rows,
})

return shop
