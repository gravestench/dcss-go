local commands = require("policy.input.commands")
local menu = require("policy.input.menu")

local items = {}

local function notice(text)
    return {
        action = "notice",
        text = text,
    }
end

local function item_step(kind, item_id, quantity)
    return {
        action = "item_step",
        kind = kind,
        item_id = item_id,
        quantity = quantity or 0,
    }
end

function items.quaff(input)
    local navigation = menu.close_or_help(input)

    if navigation then
        return navigation
    end

    local item = menu.item(input, function(candidate)
        return candidate.class == "OBJ_POTIONS"
    end)

    if item then
        return item_step(commands.quaff, item.id)
    end

    return notice("Select a potion by its inventory letter.")
end

function items.drop(input)
    local navigation = menu.close_or_help(input)

    if navigation then
        navigation.drop_quantity = ""

        return navigation
    end

    local quantity = input.drop_quantity or ""

    if input.key == "backspace" then
        return {
            action = "drop_quantity",
            value = quantity:sub(1, -2),
        }
    end

    if input.key:match("^%d$") then
        if #quantity < 8 then
            quantity = quantity .. input.key
        end

        return {
            action = "drop_quantity",
            value = quantity,
        }
    end

    local item = menu.item(input, function()
        return true
    end)

    if not item then
        return notice("Select an item by its inventory letter.")
    end

    local amount = 0

    if quantity ~= "" then
        amount = tonumber(quantity)

        if not amount then
            return notice("Invalid drop quantity.")
        end

        if amount == 0 then
            return {
                action = "screen",
                screen = "play",
                returnable = false,
                drop_quantity = "",
                notice = "Okay.",
            }
        end
    end

    return item_step(commands.drop, item.id, amount)
end

function items.wield(input)
    local navigation = menu.close_or_help(input)

    if navigation then
        return navigation
    end

    if input.key == "-" then
        return item_step(commands.wield, 0)
    end

    local item = menu.item(input, function(candidate)
        return candidate.class == "OBJ_WEAPONS"
    end)

    if item then
        return item_step(commands.wield, item.id)
    end

    return notice("Select a weapon by its inventory letter, or - for bare hands.")
end

local function armour(input, remove)
    local navigation = menu.close_or_help(input)

    if navigation then
        return navigation
    end

    local item = menu.item(input, function(candidate)
        return candidate.class == "OBJ_ARMOUR" and
            ((remove and candidate.slot ~= "") or
                (not remove and candidate.slot == ""))
    end)

    if item then
        local kind = remove and commands.take_off or commands.wear

        return item_step(kind, item.id)
    end

    return notice("Choose armour by its inventory letter, or Esc to cancel.")
end

function items.wear(input)
    return armour(input, false)
end

function items.take_off(input)
    return armour(input, true)
end

function items.throw(input)
    local navigation = menu.close_or_help(input)

    if navigation then
        return navigation
    end

    local selected = menu.item(input, function()
        return true
    end)

    if not selected then
        return notice("Select a missile by its inventory letter.")
    end

    if selected.class ~= "OBJ_MISSILES" then
        return notice("That is not a missile.")
    end

    return {
        action = "aim",
        kind = commands.throw,
        item_id = selected.id,
    }
end

return items
