local catalog = require("policy.catalog")
local monster_armour = require("policy.combat.monster_armour")

local inventory = {}

-- Check carried and equipped links against each monster after load to catch dangling or foreign items.
-- Example: inventory.validate(ctx) rejects a monster equipped with an item it does not carry.
function inventory.validate(ctx)
    local player = ctx:player()
    local slots = {}

    for _, entity in ipairs(ctx:query({ "core.carried_by" })) do
        local carrier = ctx:get(entity, "core.carried_by")

        local holder_id = ctx:id(carrier.holder)

        if holder_id ~= ctx:id(player) then
            local holder = holder_id ~= 0 and ctx:entity(holder_id) or nil
            local actor = holder and ctx:get(holder, "core.actor")
            local ai = holder and ctx:get(holder, "core.ai")
            local health = holder and ctx:get(holder, "core.health")
            local position = holder and ctx:get(holder, "core.position")
            local item = ctx:get(entity, "core.item")
            local equipped = ctx:get(entity, "core.equipped")

            if not actor or not ai or not health or health.current <= 0 or
                not position or not item then
                error("item " .. ctx:id(entity) .. " has invalid monster carrier " .. holder_id)
            end

            local kind = catalog.get("items", item.kind_id)
            local slot = equipped and equipped.slot

            if not slot then
                -- Source monster inventories can carry an unequipped item.
            elseif slot == "weapon" or slot == "alternate_weapon" then
                if kind.class ~= "OBJ_WEAPONS" or not kind.weapon then
                    error("item " .. ctx:id(entity) .. " is not a monster weapon")
                end
            elseif slot == "missile" then
                if kind.class ~= "OBJ_MISSILES" or not kind.missile then
                    error("item " .. ctx:id(entity) .. " is not monster ammunition")
                end
            elseif slot == "shield" then
                if kind.class ~= "OBJ_ARMOUR" or not kind.armour or
                    kind.armour.slot_id ~= "EQ_SHIELD" then
                    error("item " .. ctx:id(entity) .. " is not a monster shield")
                end
            elseif slot == "body" then
                if not monster_armour.wears_body(ctx, holder, kind) then
                    error("item " .. ctx:id(entity) .. " is not monster body armour")
                end
            else
                error("item " .. ctx:id(entity) .. " has unsupported monster slot " .. tostring(slot))
            end

            if slot then
                slots[holder_id] = slots[holder_id] or {}

                if slots[holder_id][slot] then
                    error("monster " .. holder_id .. " has duplicate " .. slot .. " slot")
                end

                slots[holder_id][slot] = true
            end
        end
    end
end

return inventory
