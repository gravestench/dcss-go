local colors = require("policy.presentation.colors")

local modals = {}

local classes = {
    { id = "OBJ_WEAPONS", title = "Hand Weapons" },
    { id = "OBJ_MISSILES", title = "Missiles" },
    { id = "OBJ_ARMOUR", title = "Armour" },
    { id = "OBJ_WANDS", title = "Wands" },
    { id = "OBJ_SCROLLS", title = "Scrolls" },
    { id = "OBJ_POTIONS", title = "Potions" },
}

local function letter(index)
    if index < 26 then
        return string.char(string.byte("a") + index)
    end

    return string.char(string.byte("A") + index - 26)
end

local function write(writes, x, y, text, fg)
    writes[#writes + 1] = { x = x, y = y, text = text, fg = fg }
end

local function inventory_rows(writes, inventory, height)
    write(writes, 0, 0, "Inventory: " .. #inventory .. "/52 slots", colors.white)
    local y = 2

    for _, category in ipairs(classes) do
        local indices = {}

        for index, item in ipairs(inventory) do
            if item.class == category.id then
                indices[#indices + 1] = index
            end
        end

        if #indices > 0 then
            write(writes, 0, y, category.title, colors.light_blue)
            y = y + 1

            for _, index in ipairs(indices) do
                local item = inventory[index]
                local label = item.name

                if item.quantity > 1 then
                    label = item.quantity .. " " .. label
                end

                if item.plus ~= 0 then
                    label = string.format("%+d %s", item.plus, label)
                end

                if item.slot ~= "" then
                    label = label .. " (" .. item.slot .. ")"
                end

                write(writes, 1, y, letter(index - 1) .. " - " .. label, colors.light_grey)
                y = y + 1
            end

            y = y + 1
        end
    end

    write(writes, 0, height - 2, "Esc - Return    ? - Help", colors.brown)
end

function modals.rows(input)
    local mode = input.mode
    local inventory = input.inventory or {}
    local height = input.height
    local writes = {}

    if mode == "inventory" or mode == "drop" then
        inventory_rows(writes, inventory, height)

        if mode == "drop" then
            local quantity = input.quantity or ""

            if quantity == "" then
                quantity = "all"
            end

            write(writes, 0, 0, "Drop which item? (quantity: " .. quantity .. ")", colors.white)
            write(writes, 0, height - 2,
                "Digits - Quantity    Esc - Cancel    ? - Help", colors.brown)
        end
    elseif mode == "wield" then
        write(writes, 0, 0, "Wield which item?", colors.white)
        write(writes, 1, 2, "- - bare hands", colors.light_grey)
        local y = 4

        for index, item in ipairs(inventory) do
            if item.class == "OBJ_WEAPONS" then
                local label = item.name

                if item.slot == "weapon" then
                    label = label .. " (wielded)"
                end

                write(writes, 1, y, letter(index - 1) .. " - " .. label, colors.light_grey)
                y = y + 1
            end
        end

        write(writes, 0, height - 2, "- - Bare hands    Esc - Cancel    ? - Help", colors.brown)
    elseif mode == "wear" or mode == "take_off" then
        local title = mode == "wear" and "Wear which item?" or "Take off which item?"
        write(writes, 0, 0, title, colors.white)
        local y = 2

        for index, item in ipairs(inventory) do
            local worn = item.slot ~= ""

            if item.class == "OBJ_ARMOUR" and
                ((mode == "take_off" and worn) or (mode == "wear" and not worn)) then
                local label = item.name

                if worn then
                    label = label .. " (worn)"
                end

                write(writes, 1, y, letter(index - 1) .. " - " .. label, colors.light_grey)
                y = y + 1
            end
        end

        write(writes, 0, height - 2, "Esc - Cancel    ? - Help", colors.brown)
    elseif mode == "quaff" then
        write(writes, 0, 0, "Quaff which potion?", colors.white)
        local y = 2

        for index, item in ipairs(inventory) do
            if item.class == "OBJ_POTIONS" then
                local label = item.name

                if item.quantity > 1 then
                    label = item.quantity .. " " .. label
                end

                write(writes, 1, y, letter(index - 1) .. " - " .. label, colors.light_grey)
                y = y + 1
            end
        end

        if y == 2 then
            write(writes, 1, y, "You have no potions.", colors.brown)
        end

        write(writes, 0, height - 2, "Esc - Cancel    ? - Help", colors.brown)
    else
        error("unknown inventory modal " .. tostring(mode))
    end

    return { writes = writes }
end

register.policy({
    id = "presentation.inventory_modal",
    run = function(_, input)
        return modals.rows(input)
    end,
})

return modals
