local catalog = require("policy.catalog")

local equipment = {}

local function validate_item(item, kind)
    if item.quantity <= 0 or (not kind.stackable and item.quantity ~= 1) then
        error("impossible quantity")
    end

    if item.charges < 0 or (item.charges ~= 0 and kind.class ~= "OBJ_WANDS") then
        error("impossible charges")
    end

    if item.plus ~= 0 and kind.class ~= "OBJ_WEAPONS" and kind.class ~= "OBJ_ARMOUR" then
        error("impossible enchantment")
    end

    if item.plus < -32768 or item.plus > 32767 then
        error("enchantment outside source item range")
    end

    if item.ego == "" then
        return
    end

    if kind.class == "OBJ_WEAPONS" and kind.weapon then
        for _, brand in ipairs(kind.weapon.brand_weights or {}) do
            if brand.brand_id == item.ego and brand.weight > 0 and
                item.ego ~= "SPWPN_NORMAL" then
                return
            end
        end
    end

    if item.ego == "poisoned" or item.ego == "curare" or item.ego == "dispersal" then
        if kind.class ~= "OBJ_MISSILES" then
            error("incompatible ego")
        end

        return
    end

    error("unknown ego " .. item.ego)
end

function equipment.find(ctx, monster, slot_name)
    for _, item_entity in ipairs(ctx:query({ "core.equipped" })) do
        local equipped = ctx:get(item_entity, "core.equipped")

        if equipped.slot == slot_name then
            local carried = ctx:get(item_entity, "core.carried_by")

            if carried and carried.holder == monster then
                local item = ctx:get(item_entity, "core.item")

                if not item then
                    error("monster equipped item " .. ctx:id(item_entity) .. " has no item")
                end

                local kind = catalog.get("items", item.kind_id)
                validate_item(item, kind)

                return item_entity, item, kind
            end
        end
    end

    return nil, nil, nil
end

return equipment
