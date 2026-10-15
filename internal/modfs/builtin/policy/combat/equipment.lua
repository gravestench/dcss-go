local catalog = require("policy.catalog")
local items = require("policy.inventory.items")

local equipment = {}

local function has_flag(flags, wanted)
    for _, flag in ipairs(flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

function equipment.worn(ctx, holder, slots)
    local result = {}

    for _, entity in ipairs(ctx:query({ "core.equipped", "core.carried_by" })) do
        local carrier = ctx:get(entity, "core.carried_by")
        local equipped = ctx:get(entity, "core.equipped")

        if carrier.holder == holder and slots[equipped.slot] then
            if result[equipped.slot] then
                error("duplicate equipped " .. equipped.slot)
            end

            local item = ctx:get(entity, "core.item")

            if not item then
                error("equipped entity has no item")
            end

            local definition = catalog.get("items", item.kind_id)
            items.validate(item, definition)

            result[equipped.slot] = {
                entity = entity,
                item = item,
                definition = definition,
            }
        end
    end

    return result
end

function equipment.monster_melee(ctx, monster)
    for _, entity in ipairs(ctx:query({ "core.equipped", "core.carried_by" })) do
        local carrier = ctx:get(entity, "core.carried_by")
        local slot = ctx:get(entity, "core.equipped")

        if carrier.holder == monster and slot.slot ~= "weapon" and
            slot.slot ~= "alternate_weapon" and slot.slot ~= "missile" and
            slot.slot ~= "shield" then
            error("monster has unsupported equipment slot " .. slot.slot)
        end
    end

    local worn = equipment.worn(ctx, monster, {
        weapon = true,
        alternate_weapon = true,
    })

    for _, slot in ipairs({ "weapon", "alternate_weapon" }) do
        local entry = worn[slot]

        if entry then
            local definition = entry.definition

            if definition.class ~= "OBJ_WEAPONS" or not definition.weapon then
                error("monster has non-weapon in " .. slot)
            end

            if not has_flag(definition.weapon.damage_flags, "DAMV_NON_MELEE") then
                return {
                    damage = definition.weapon.damage,
                    hit = definition.weapon.hit,
                    plus = entry.item.plus,
                    brand = entry.item.ego,
                }
            end
        end
    end

    return nil
end

function equipment.monster_shield(ctx, monster)
    local worn = equipment.worn(ctx, monster, { shield = true })
    local shield = worn.shield

    if not shield then
        return nil
    end

    local definition = shield.definition

    if definition.class ~= "OBJ_ARMOUR" or not definition.armour or
        definition.armour.slot_id ~= "EQ_SHIELD" then
        error("monster has non-shield in shield slot")
    end

    return shield
end

function equipment.protection_ac(ctx, monster)
    local weapon = equipment.monster_melee(ctx, monster)

    if weapon and weapon.brand == "SPWPN_PROTECTION" then
        return 5
    end

    return 0
end

return equipment
