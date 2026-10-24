local object_classes = require("ids.object_classes")
local colors = require("policy.presentation.colors")
local input_items = require("policy.input.items")

local modals = {}

local classes = {
    { id = object_classes.OBJ_WEAPONS, title = "Hand Weapons" },
    { id = object_classes.OBJ_STAVES, title = "Magical Staves" },
    { id = object_classes.OBJ_MISSILES, title = "Missiles" },
    { id = object_classes.OBJ_ARMOUR, title = "Armour" },
    { id = object_classes.OBJ_JEWELLERY, title = "Jewellery" },
    { id = object_classes.OBJ_WANDS, title = "Wands" },
    { id = object_classes.OBJ_SCROLLS, title = "Scrolls" },
    { id = object_classes.OBJ_POTIONS, title = "Potions" },
    { id = object_classes.OBJ_MISCELLANY, title = "Miscellaneous" },
}

local item_modes = {
    quaff = {
        title = "Quaff which potion?",
        class = object_classes.OBJ_POTIONS,
        empty = "You have no potions.",
    },
    read = {
        title = "Read which scroll?",
        class = object_classes.OBJ_SCROLLS,
        empty = "You have no scrolls.",
    },
    throw = {
        title = "Throw which missile?",
        class = object_classes.OBJ_MISSILES,
        empty = "You have no missiles.",
    },
    evoke_wand = {
        title = "Evoke which wand?",
        class = object_classes.OBJ_WANDS,
        empty = "You have no wands.",
    },
    evoke_item = {
        title = "Evoke which item?",
        accept = input_items.xp_evoker,
        empty = "You have no evokable items.",
    },
}

-- Use one stable letter sequence across inventory and action prompts so a
-- displayed key selects the same item after the modal changes mode.
local function letter(index)
    if index < 26 then
        return string.char(string.byte("a") + index)
    end

    return string.char(string.byte("A") + index - 26)
end

-- Return renderer data rather than escape codes; the terminal owns clipping
-- when the player resizes while a modal is open.
local function write(writes, x, y, text, fg)
    writes[#writes + 1] = { x = x, y = y, text = text, fg = fg }
end

-- Inventory modal letters are assigned to the current item rows.
-- Group by object class for readability while retaining the original
-- inventory index in each label, which is what input routing expects.
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

-- Modal rows are built from the active screen state; inventory letters stay aligned with input selection.
-- Example: modals.rows({ mode = "inventory", inventory = items, height = 24 })
-- returns writes using the same letters that policy.input.items accepts.
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
            if input_items.weapon(item) then
                local label = item.name

                if item.slot == "weapon" then
                    label = label .. " (wielded)"
                end

                write(writes, 1, y, letter(index - 1) .. " - " .. label, colors.light_grey)
                y = y + 1
            end
        end

        write(writes, 0, height - 2, "- - Bare hands    Esc - Cancel    ? - Help", colors.brown)
    elseif mode == "wear" or mode == "take_off" or
        mode == "put_on" or mode == "remove_jewellery" then
        local title = mode == "wear" and "Wear which item?" or "Take off which item?"

        if mode == "put_on" then
            title = "Put on which piece of jewellery?"
        elseif mode == "remove_jewellery" then
            title = "Remove which piece of jewellery?"
        end

        write(writes, 0, 0, title, colors.white)
        local y = 2

        for index, item in ipairs(inventory) do
            local worn = item.slot ~= ""
            local accepted = (mode == "wear" and input_items.unworn_armour(item)) or
                (mode == "take_off" and input_items.worn_armour(item)) or
                (mode == "put_on" and input_items.unworn_jewellery(item)) or
                (mode == "remove_jewellery" and input_items.worn_jewellery(item))

            if accepted then
                local label = item.name

                if worn then
                    label = label .. " (worn)"
                end

                write(writes, 1, y, letter(index - 1) .. " - " .. label, colors.light_grey)
                y = y + 1
            end
        end

        write(writes, 0, height - 2, "Esc - Cancel    ? - Help", colors.brown)
    elseif item_modes[mode] then
        local chosen = item_modes[mode]
        write(writes, 0, 0, chosen.title, colors.white)
        local y = 2

        for index, item in ipairs(inventory) do
            local accepted = chosen.accept and chosen.accept(item) or
                item.class == chosen.class

            if accepted then
                local label = item.name

                if item.quantity > 1 then
                    label = item.quantity .. " " .. label
                end

                write(writes, 1, y, letter(index - 1) .. " - " .. label, colors.light_grey)
                y = y + 1
            end
        end

        if y == 2 then
            write(writes, 1, y, chosen.empty, colors.brown)
        end

        write(writes, 0, height - 2, "Esc - Cancel    ? - Help", colors.brown)
    else
        error("unknown inventory modal " .. tostring(mode))
    end

    return { writes = writes }
end

-- The policy entrypoint returns rows for the current modal; input routing interprets the same item letters.
-- It stays a small adapter so direct Lua callers can test row construction
-- without supplying a game context they do not need.
function modals.run(_, input)
    return modals.rows(input)
end

register.policy({
    id = "presentation.inventory_modal",
    run = modals.run,
})

return modals
