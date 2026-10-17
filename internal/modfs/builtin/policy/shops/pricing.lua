local catalog = require("policy.catalog")
local classes = require("ids.object_classes")
local component = require("constants.component")
local identification = require("policy.items.identification")
local artefacts = require("policy.shops.value.artefacts")

local pricing = {}

-- Each class owns its source valuation rule. A modded item may name a
-- replacement module on its own definition without editing this table.
local class_rules = {
    [classes.OBJ_WEAPONS] = require("policy.shops.value.weapons"),
    [classes.OBJ_ARMOUR] = require("policy.shops.value.armour"),
    [classes.OBJ_MISSILES] = require("policy.shops.value.missiles"),
    [classes.OBJ_POTIONS] = require("policy.shops.value.potions"),
    [classes.OBJ_SCROLLS] = require("policy.shops.value.scrolls"),
    [classes.OBJ_WANDS] = require("policy.shops.value.wands"),
    [classes.OBJ_JEWELLERY] = require("policy.shops.value.jewellery"),
    [classes.OBJ_BOOKS] = require("policy.shops.value.books"),
    [classes.OBJ_MISCELLANY] = require("policy.shops.value.miscellany"),
    [classes.OBJ_STAVES] = require("policy.shops.value.fixed"),
    [classes.OBJ_ORBS] = require("policy.shops.value.fixed"),
    [classes.OBJ_RUNES] = require("policy.shops.value.fixed"),
    [classes.OBJ_GOLD] = require("policy.shops.value.fixed"),
    [classes.OBJ_FOOD] = require("policy.shops.value.fixed"),
    [classes.OBJ_RODS] = require("policy.shops.value.fixed"),
    [classes.OBJ_CORPSES] = require("policy.shops.value.fixed"),
}

local function stepdown(value)
    -- Source: stepdown.cc:stepdown_value(value, 1000, 1000, 10000, 10000).
    if value < 1000 then
        return value
    end

    return math.min(10000,
        math.floor(1000 * math.log(1 + value / 1000) / math.log(2)))
end

function pricing.item_value(kind, item, known, artefact, options)
	local fixed = known and known.properties and
        artefacts.fixed_value(artefact)

    if fixed then
        -- Source returns a known unrand's fixed value before stepdown and
        -- quantity handling.
        return fixed
    end

    local rule = class_rules[kind.class]

    if kind.shop_value_module then
        rule = require(kind.shop_value_module)
    end

    if not rule or type(rule.value) ~= "function" then
        error("item " .. kind.id .. " has no shop value rule")
    end

    if type(item.quantity) ~= "number" or item.quantity < 1 or
        item.quantity % 1 ~= 0 then
        error("shop item has invalid quantity")
    end

    local value = kind.shop_value or rule.value(kind, item,
        known or {}, artefact, options)

    if type(value) ~= "number" or value % 1 ~= 0 then
        error("item " .. kind.id .. " has invalid shop value")
    end

    return item.quantity * stepdown(math.max(1, value))
end

function pricing.value(ctx, item_entity, identifies_stock)
    local item = ctx:get(item_entity, component.ITEM)

    if not item then
        error("shop value requires an item entity")
    end

    local known

    if identifies_stock then
        known = {
            type = true,
            pluses = true,
            properties = true,
        }
    else
        known = identification.known(ctx, ctx:player(), item_entity)
    end

    local state = ctx:get(item_entity, component.ITEM_IDENTIFICATION)
    known.cosmetic = state and state.cosmetic or 0
    local options = ctx:get(item_entity, component.ITEM_RANDOM_BOOK)

    return pricing.item_value(catalog.get("items", item.kind_id),
        item, known, ctx:get(item_entity, component.ITEM_ARTEFACT), options)
end

function pricing.price(greed, value)
    if type(greed) ~= "number" or greed < 0 or greed % 1 ~= 0 or
        type(value) ~= "number" or value < 0 or value % 1 ~= 0 then
        error("invalid shop greed or item value")
    end

    return math.max(1, math.floor(greed * value / 10))
end

function pricing.quote(ctx, shop_entity, item_entity)
    local shop = ctx:get(shop_entity, component.SHOP)

    if not shop then
        error("shop quote requires a shop")
    end

    local definition = catalog.get("shops", shop.kind_id)
    local value = pricing.value(ctx, item_entity,
        definition.identifies_stock)

    return pricing.price(shop.greed, value)
end

return pricing
