local commands = require("policy.input.commands")
local classes = require("ids.object_classes")
local menu = require("policy.input.menu")

local items = {}

function items.any_item()
    return true
end

function items.potion(candidate)
    return candidate.class == classes.OBJ_POTIONS
end

function items.scroll(candidate)
    return candidate.class == classes.OBJ_SCROLLS
end

function items.wand(candidate)
    return candidate.class == "OBJ_WANDS"
end

function items.weapon(candidate)
    return candidate.class == "OBJ_WEAPONS"
end

function items.worn_armour(candidate)
    return candidate.class == "OBJ_ARMOUR" and candidate.slot ~= ""
end

function items.unworn_armour(candidate)
    return candidate.class == "OBJ_ARMOUR" and candidate.slot == ""
end

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

    local item = menu.item(input, items.potion)

    if item then
        return item_step(commands.quaff, item.id)
    end

    return notice("Select a potion by its inventory letter.")
end

function items.read(input)
    local navigation = menu.close_or_help(input)

    if navigation then
        return navigation
    end

    local item = menu.item(input, items.scroll)

    if item then
        return item_step(commands.read, item.id)
    end

    return notice("Select a scroll by its inventory letter.")
end

function items.evoke_wand(input)
    local navigation = menu.close_or_help(input)

    if navigation then
        return navigation
    end

    local item = menu.item(input, items.wand)

    if item then
        return {
            action = "aim",
            kind = commands.evoke_wand,
            item_id = item.id,
        }
    end

    return notice("Select a wand by its inventory letter.")
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

    local item = menu.item(input, items.any_item)

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

    local item = menu.item(input, items.weapon)

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

    local accepted = remove and items.worn_armour or items.unworn_armour
    local item = menu.item(input, accepted)

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

    local selected = menu.item(input, items.any_item)

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
