local commands = require("policy.input.commands")
local classes = require("ids.object_classes")
local menu = require("policy.input.menu")
local evokers = require("policy.inventory.evokers")

local items = {}

-- Item menus turn letters into entity selections, preserving the pending command across screens.
-- Drop accepts any carried class; this predicate lets the shared menu
-- selector handle its letters without adding a class-specific branch.
-- Example: menu.item(input, items.any_item) resolves a drop selection.
function items.any_item()
    return true
end

-- Filter before quaffing so a matching letter on a non-potion item cannot
-- become a potion command after the inventory is reordered.
function items.potion(candidate)
    return candidate.class == classes.OBJ_POTIONS
end

-- Use the catalog class rather than the displayed name, which may be an
-- unidentified scroll appearance.
function items.scroll(candidate)
    return candidate.class == classes.OBJ_SCROLLS
end

-- Keep wand aiming restricted to wand entities; other evokable items may
-- share inventory letters but need different target rules.
function items.wand(candidate)
    return candidate.class == "OBJ_WANDS"
end

-- Miscellany contains non-evokable utility objects too. The menu accepts
-- only registered XP evokers, independent of the displayed item name.
function items.xp_evoker(candidate)
    return candidate.class == classes.OBJ_MISCELLANY and
        evokers.definition(candidate.kind_id) ~= nil
end

-- Magical staves occupy the weapon slot too, so wield selection includes
-- them alongside ordinary weapon-class items.
function items.weapon(candidate)
    return candidate.class == classes.OBJ_WEAPONS or
        candidate.class == classes.OBJ_STAVES
end

-- Take-off lists only armour with a saved equipped slot; otherwise a loose
-- carried piece could be selected for a removal action.
function items.worn_armour(candidate)
    return candidate.class == "OBJ_ARMOUR" and candidate.slot ~= ""
end

-- Wear lists only loose armour, avoiding an already-equipped item that
-- would produce a redundant command.
function items.unworn_armour(candidate)
    return candidate.class == "OBJ_ARMOUR" and candidate.slot == ""
end

-- Jewellery removal uses the saved slot rather than the item's appearance,
-- since a ring can remain unidentified while worn.
function items.worn_jewellery(candidate)
    return candidate.class == classes.OBJ_JEWELLERY and
        candidate.slot ~= ""
end

-- Putting jewellery on starts from loose carried pieces; the equipment
-- policy chooses the actual legal slot later.
function items.unworn_jewellery(candidate)
    return candidate.class == classes.OBJ_JEWELLERY and
        candidate.slot == ""
end

-- Keep invalid selections on the current modal with a visible explanation,
-- rather than silently closing it or spending a turn.
local function notice(text)
    return {
        action = "notice",
        text = text,
    }
end

-- A menu step keeps the selected item and pending command together across prompts.
-- Use entity ID, not a copied item record, so later command preparation can
-- revalidate ownership and quantity against live ECS state.
local function item_step(kind, item_id, quantity)
    return {
        action = "item_step",
        kind = kind,
        item_id = item_id,
        quantity = quantity or 0,
    }
end

-- Translate a potion letter into a prepared quaff command only after the
-- class filter succeeds; the action bridge still performs effect validation.
-- Example: items.quaff({ key = "a", inventory = items_shown }).
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

-- Keep scroll reading on the same letter-to-entity path as quaffing while
-- preserving its distinct command ID and future targeting prompt.
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

-- Defer the wand's direction choice to aim mode so selection does not fire
-- the spell or spend a charge before a target exists.
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

-- Immediate effects open a timed command; aimed effects first allow a
-- no-time target choice. The command rechecks inventory and charges.
function items.evoke_item(input)
    local navigation = menu.close_or_help(input)

    if navigation then
        return navigation
    end

    local item = menu.item(input, items.xp_evoker)

    if not item then
        return notice("Select an evokable item by its inventory letter.")
    end

    if evokers.aimed(item.kind_id) then
        return {
            action = "aim",
            kind = commands.evoke_item,
            item_id = item.id,
        }
    end

    return item_step(commands.evoke_item, item.id)
end

-- Dropping may first collect a quantity, then resolves the inventory letter into an item entity.
-- Quantity digits live in input state until an item letter completes the
-- request; zero cancels safely instead of creating a zero-stack intent.
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

-- Treat '-' as an intentional return to bare hands, while ordinary letters
-- pass through the weapon/staff filter before the command is prepared.
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

-- Wear and take-off share this menu route but filter opposite equipment states.
-- The final command keeps the selected entity ID so the equipment policy
-- can still reject a stale or no-longer-carried item at execution time.
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

-- Reuse the shared armour route with the loose-item filter, so wear and
-- removal keep identical letter and navigation behavior.
function items.wear(input)
    return armour(input, false)
end

-- Reuse the same route with the equipped-item filter; only the predicate and
-- command ID differ, keeping take-off controls aligned with wear controls.
function items.take_off(input)
    return armour(input, true)
end

-- Share jewellery letter handling between put-on and removal, selecting by
-- slot state while leaving anatomy and form checks to the owner policy.
local function jewellery(input, remove)
    local navigation = menu.close_or_help(input)

    if navigation then
        return navigation
    end

    local accepted = remove and items.worn_jewellery or
        items.unworn_jewellery
    local selected = menu.item(input, accepted)

    if selected then
        local kind = remove and commands.take_off or commands.wear

        return item_step(kind, selected.id)
    end

    return notice("Choose jewellery by its inventory letter, or Esc to cancel.")
end

-- Pass a loose jewellery choice through shared selection so later slot rules
-- can decide where it may be worn without duplicating menu logic.
function items.put_on(input)
    return jewellery(input, false)
end

-- Use the same letter handling as put-on but require a worn slot; this keeps
-- removal from selecting an unidentified but merely carried ring.
function items.remove_jewellery(input)
    return jewellery(input, true)
end

-- Keep the explicit non-missile notice after letter selection; the throw
-- command needs a separate aim step and should not reinterpret other items.
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
