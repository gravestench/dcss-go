-- Source: item-prop.cc and invent.cc.
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

-- Example: a weapon at the +9 cap cannot gain another Enchant Weapon point.
-- Unknown pluses remain eligible for discovery; known +9 weapons and artefacts cannot gain more.
function enchantable.weapon(ctx, player, entity)
    if ctx:has(entity, component.ITEM_ARTEFACT) then
        return false
    end

    local item = ctx:get(entity, component.ITEM)
    local kind = catalog.get("items", item.kind_id)

    if kind.class ~= classes.OBJ_WEAPONS then
        return false
    end

    local known = identification.known(ctx, player, entity)

    return not known.pluses or item.plus < MAX_WEAPON_PLUS
end

-- Use source armour caps: body AC, barding AC, shield formula, or two for secondary slots.
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

-- Exclude artefacts and zero-cap armour, then compare known pluses against the subtype cap.
function enchantable.armour(ctx, player, entity)
    if ctx:has(entity, component.ITEM_ARTEFACT) then
        return false
    end

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
