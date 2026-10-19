local catalog = require("policy.catalog")
local items = require("policy.inventory.items")

local equipment = {}

-- AI equipment lookup accepts only the monster's item equipped in the requested slot.
-- Example: equipment.find(ctx, monster, "weapon") checks carried equipment before a ranged action.
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
                items.validate(item, kind)

                return item_entity, item, kind
            end
        end
    end

    return nil, nil, nil
end

return equipment
