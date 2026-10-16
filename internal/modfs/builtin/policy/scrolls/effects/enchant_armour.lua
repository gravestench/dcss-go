-- Source: item-use.cc:_handle_enchant_armour and enchant_armour.
local catalog = require("policy.catalog")
local choice = require("policy.scrolls.item_choice")
local component = require("constants.component")
local enchantable = require("policy.scrolls.enchantable")
local identification = require("policy.items.identification")
local item_ids = require("ids.items")
local scrolls = require("policy.scrolls")

local enchant_armour = {}

function enchant_armour.prepare(ctx, player, request)
    return choice.prepare(ctx, player, request,
        "Enchant which item?", "You have no enchantable armour.",
        enchantable.armour)
end

function enchant_armour.apply(ctx, player, request)
    local target = choice.target(ctx, request)
    local item = ctx:get(target, component.ITEM)
    local kind = catalog.get("items", item.kind_id)
    local name = identification.name(ctx, player, target)

    if item.plus >= enchantable.armour_cap(kind) then
        ctx:emit("read", "Nothing happens.")

        return
    end

    item.plus = item.plus + 1
    ctx:set(target, component.ITEM, item)
    ctx:emit("read", name .. " glows green for a moment.")
end

scrolls.register(item_ids.SCR_ENCHANT_ARMOUR, enchant_armour)

return enchant_armour
