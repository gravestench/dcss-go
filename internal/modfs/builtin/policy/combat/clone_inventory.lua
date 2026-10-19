-- A cloned monster owns new item entities. Sharing the old entity would let
-- either body wield, enchant, or lose the other's weapon through one record.
local component = require("constants.component")

local inventory = {}

local attachments = {
    component.EQUIPPED,
    component.ITEM_ARTEFACT,
    component.ITEM_IDENTIFICATION,
    component.ITEM_MANUAL,
    component.ITEM_RANDOM_BOOK,
    component.JEWELLERY_ATTUNEMENT,
}

-- Duplicate item-owned records without copying the old carrier or a vault
-- origin. The copy's holder is the new actor and later changes stay local.
function inventory.copy(ctx, source, twin)
    for _, item in ipairs(ctx:query({
        component.ITEM,
        component.CARRIED_BY,
    })) do
        local carrier = ctx:get(item, component.CARRIED_BY)

        if carrier.holder == source then
            local copy = ctx:create()

            ctx:add(copy, component.ITEM,
                ctx:get(item, component.ITEM))
            ctx:add(copy, component.CARRIED_BY, {
                holder = twin,
            })

            for _, key in ipairs(attachments) do
                local state = ctx:get(item, key)

                if state then
                    ctx:add(copy, key, state)
                end
            end
        end
    end
end

return inventory
