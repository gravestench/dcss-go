-- Source: item-prop.cc:1199-1232 and invent.cc:1125-1146.
local catalog = require("policy.catalog")
local slots = require("constants.armour_slots")
local classes = require("ids.object_classes")
local component = require("constants.component")
local identification = require("policy.items.identification")
local item_ids = require("ids.items")

local enchantable = {}
local MAX_WEAPON_PLUS = 9
local MAX_SECONDARY_PLUS = 2

local excluded_armour = {
    [item_ids.ARM_QUICKSILVER_DRAGON_ARMOUR] = true,
    [item_ids.ARM_SCARF] = true,
    [item_ids.ARM_ORB] = true,
}

function enchantable.weapon(ctx, player, entity)
    local item = ctx:get(entity, component.ITEM)
    local kind = catalog.get("items", item.kind_id)

    if kind.class ~= classes.OBJ_WEAPONS then
        return false
    end

    local known = identification.known(ctx, player, entity)

    return not known.pluses or item.plus < MAX_WEAPON_PLUS
end

function enchantable.armour_cap(kind)
    if kind.class ~= classes.OBJ_ARMOUR or
        excluded_armour[kind.id] then
        return 0
    end

    local armour = kind.armour

    if armour.slot_id == slots.BODY_ARMOUR or
        kind.id == item_ids.ARM_BARDING then
        return armour.ac
    end

    if armour.slot_id == slots.SHIELD then
        return math.floor((armour.ac - 3) / 2) + 3
    end

    return MAX_SECONDARY_PLUS
end

function enchantable.armour(ctx, player, entity)
    local item = ctx:get(entity, component.ITEM)
    local kind = catalog.get("items", item.kind_id)
    local cap = enchantable.armour_cap(kind)

    if cap == 0 then
        return false
    end

    local known = identification.known(ctx, player, entity)

    return not known.pluses or item.plus < cap
end

return enchantable
