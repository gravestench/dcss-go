local catalog = require("policy.catalog")
local armour_egos = require("constants.armour_egos")
local identification = require("policy.items.identification")
local brand_pool = require("policy.inventory.brand_pool")
local classes = require("ids.object_classes")

local items = {}
local supported_armour_egos = {
    [armour_egos.PROTECTION] = true,
    [armour_egos.RESISTANCE] = true,
    [armour_egos.FIRE_RESISTANCE] = true,
    [armour_egos.COLD_RESISTANCE] = true,
    [armour_egos.POSITIVE_ENERGY] = true,
    [armour_egos.SPIRIT_SHIELD] = true,
    [armour_egos.WILLPOWER] = true,
    [armour_egos.GUILE] = true,
    [armour_egos.STEALTH] = true,
}

function items.kind(item)
    return catalog.get("items", item.kind_id)
end

function items.phrase(name, quantity)
    if quantity > 1 then
        local before, after = name:match("^(.-)( of .*)$")

        if before and before ~= "" then
            return quantity .. " " .. before .. "s" .. after
        end

        return quantity .. " " .. name .. "s"
    end

    local article = name:match("^[aeiouAEIOU]") and "an" or "a"

    return article .. " " .. name
end

function items.validate(item, kind)
    if item.quantity <= 0 or (not kind.stackable and item.quantity ~= 1) then
        error("impossible quantity")
    end

    if item.charges < 0 or (item.charges ~= 0 and kind.class ~= "OBJ_WANDS") then
        error("impossible charges")
    end

    local jewellery_pluses = kind.class == classes.OBJ_JEWELLERY and
        kind.jewellery and
        kind.jewellery.pluses == true

    if item.plus ~= 0 and kind.class ~= "OBJ_WEAPONS" and
        kind.class ~= "OBJ_ARMOUR" and not jewellery_pluses then
        error("impossible enchantment")
    end

    if item.plus < -32768 or item.plus > 32767 then
        error("enchantment outside source item range")
    end

    if item.ego == "" then
        return
    end

    if kind.class == "OBJ_WEAPONS" and kind.weapon then
        -- Chaos Knight starts with a forced chaos brand. Generation weights
        -- describe random rolls, not every brand the source can place.
        if item.ego == "SPWPN_CHAOS" then
            return
        end

        if brand_pool.contains(kind, item.ego) then
            return
        end

        local brands = type(kind.weapon.brand_weights) == "table" and
            kind.weapon.brand_weights or {}

        for _, brand in ipairs(brands) do
            if brand.brand_id == item.ego and brand.weight > 0 and item.ego ~= "SPWPN_NORMAL" then
                return
            end
        end
    end

    if kind.class == "OBJ_ARMOUR" and supported_armour_egos[item.ego] then
        return
    end

    if item.ego == "poisoned" or item.ego == "curare" or
        item.ego == "dispersal" or item.ego == "blinding" or
        item.ego == "frenzy" then
        if kind.class == "OBJ_MISSILES" then
            return
        end

        error("incompatible ego")
    end

    error("unknown ego " .. item.ego)
end

function items.prepare_pickup(ctx, actor, pending_vault_item)
    local position = ctx:get(actor, "core.position")

    if not position then
        error("pickup actor " .. ctx:id(actor) .. " has no position")
    end

    local corpse

    for _, entity in ipairs(items.at(ctx, position)) do
        if ctx:has(entity, "core.corpse") then
            corpse = true
        else
            return { intent = { kind = 3 }, cost = 10 }
        end
    end

    if corpse then
        return { message = "You can't pick that up." }
    end

    if pending_vault_item and pending_vault_item ~= "" then
        return { message = "The " .. pending_vault_item .. " is unavailable in this port." }
    end

    return { message = "There is nothing to pick up here." }
end

function items.prepare_drop(ctx, actor, item_id, quantity)
    if quantity < 0 then
        return { message = "Drop quantity must be positive." }
    end

    local entity = item_id ~= 0 and ctx:entity(item_id) or nil
    local item = entity and ctx:get(entity, "core.item")
    local carrier = entity and ctx:get(entity, "core.carried_by")

    if not item or not carrier or carrier.holder ~= actor then
        return { message = "You are not carrying that item." }
    end

    items.validate(item, items.kind(item))
    local equipped = ctx:get(entity, "core.equipped")

    if equipped and equipped.slot ~= "weapon" then
        return { message = "You will have to take that off first." }
    end

    if quantity == 0 or quantity > item.quantity then
        quantity = item.quantity
    end

    return {
        intent = { kind = 10, item_id = entity, quantity = quantity },
        cost = 10,
    }
end

function items.matches(left, right)
    -- Lua host component integers are exact through 2^53-1.
    return type(left.quantity) == "number" and type(right.quantity) == "number" and
        left.quantity > 0 and right.quantity > 0 and
        left.quantity <= 9007199254740991 - right.quantity and
        left.kind_id == right.kind_id and left.plus == right.plus and
        left.charges == right.charges and left.ego == right.ego
end

function items.at(ctx, position)
    local found = {}

    for _, entity in ipairs(ctx:query({ "core.item", "core.position" })) do
        local location = ctx:get(entity, "core.position")

        if location.level_id == position.level_id and location.x == position.x and
            location.y == position.y and not ctx:has(entity, "core.carried_by") then
            found[#found + 1] = entity
        end
    end

    return found
end

function items.carried_stack(ctx, actor, source)
    local item = ctx:get(source, "core.item")

    if not items.kind(item).stackable then
        return nil
    end

    for _, entity in ipairs(ctx:query({ "core.carried_by", "core.item" })) do
        local carrier = ctx:get(entity, "core.carried_by")

        if carrier.holder == actor and
            items.matches(ctx:get(entity, "core.item"), item) and
            identification.compatible(ctx, entity, source) then
            return entity
        end
    end

    return nil
end

function items.floor_stack(ctx, position, item, exclude)
    if not items.kind(item).stackable then
        return nil
    end

    for _, entity in ipairs(items.at(ctx, position)) do
        if entity ~= exclude and not ctx:has(entity, "core.corpse") and
            items.matches(ctx:get(entity, "core.item"), item) and
            (not exclude or
                identification.compatible(ctx, entity, exclude)) then
            return entity
        end
    end

    return nil
end

return items
