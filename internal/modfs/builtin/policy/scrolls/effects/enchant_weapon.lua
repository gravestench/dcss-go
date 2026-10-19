-- Source: item-use.cc:_handle_enchant_weapon and enchant_weapon.
local choice = require("policy.scrolls.item_choice")
local component = require("constants.component")
local enchantable = require("policy.scrolls.enchantable")
local identification = require("policy.items.identification")
local item_ids = require("ids.items")
local scrolls = require("policy.scrolls")

local enchant_weapon = {}

-- Example: a weapon at its enchantment cap is not offered as a target.
-- Build a choice only from reachable weapons whose known plus can still increase.
function enchant_weapon.prepare(ctx, player, request)
    return choice.prepare(ctx, player, request,
        "Enchant which weapon?", "You have no enchantable weapons.",
        enchantable.weapon)
end

-- Recheck the +9 cap at apply time before changing the selected weapon.
function enchant_weapon.apply(ctx, player, request)
    local target = choice.target(ctx, request)
    local item = ctx:get(target, component.ITEM)
    local name = identification.name(ctx, player, target)

    if item.plus >= 9 then
        ctx:emit("read", "Nothing happens.")

        return
    end

    item.plus = item.plus + 1
    ctx:set(target, component.ITEM, item)
    ctx:emit("read", name .. " glows red for a moment.")
end

scrolls.register(item_ids.SCR_ENCHANT_WEAPON, enchant_weapon)

return enchant_weapon
