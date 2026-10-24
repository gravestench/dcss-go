local catalog = require("policy.catalog")
local items = require("policy.inventory.items")
local enchant = require("policy.combat.monster_enchant")
local forms = require("policy.magic.effects.forms.player")
local component = require("constants.component")
local artefact_ids = require("ids.artefact_properties")
local item_use = require("constants.monster_item_use")
local monster_flags = require("constants.monster_flags")
local object_classes = require("ids.object_classes")

local equipment = {}

-- Exclude non-melee weapon definitions when choosing a monster's contact weapon.
local function has_flag(flags, wanted)
    for _, flag in ipairs(flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Example: equipment.worn(ctx, holder, slots) with melded shield slot -> no active shield entry
-- Player forms can disable equipped slots without removing their inventory entities.
function equipment.worn(ctx, holder, slots)
    local result = {}

    for _, entity in ipairs(ctx:query({ "core.equipped", "core.carried_by" })) do
        local carrier = ctx:get(entity, "core.carried_by")
        local equipped = ctx:get(entity, "core.equipped")

        if carrier.holder == holder and slots[equipped.slot] and
            (holder ~= ctx:player() or
                forms.slot_usable(ctx, holder, equipped.slot)) then
            if result[equipped.slot] then
                error("duplicate equipped " .. equipped.slot)
            end

            local item = ctx:get(entity, "core.item")

            if not item then
                error("equipped entity has no item")
            end

            local definition = catalog.get("items", item.kind_id)
            items.validate(item, definition)
            local artefact = ctx:get(entity, component.ITEM_ARTEFACT)
            local ego = artefact and artefact.brand ~= "" and
                artefact.brand or item.ego

            result[equipped.slot] = {
                entity = entity,
                item = item,
                definition = definition,
                ego = ego,
            }
        end
    end

    return result
end

-- The source scans artefacts only on item-using monsters. A second weapon
-- contributes only when the monster really wields both weapons.
function equipment.monster_artefact_value(ctx, monster, definition,
    property_id)
    if definition.item_use_id ~= item_use.STARTING_EQUIPMENT and
        definition.item_use_id ~= item_use.WEAPONS_ARMOUR then
        return 0
    end

    local dual_wielder = has_flag(definition.flags,
        monster_flags.TWO_WEAPONS)
    local worn = equipment.worn(ctx, monster, {
        weapon = true,
        alternate_weapon = true,
        body = true,
        shield = true,
        jewellery = true,
    })
    local properties = require(
        "policy.item_generation.artefacts.properties")
    local value = 0

    for slot, entry in pairs(worn) do
        local class = entry.definition.class
        local active = (slot == "weapon" and
            class == object_classes.OBJ_WEAPONS) or
            (slot == "alternate_weapon" and dual_wielder and
                class == object_classes.OBJ_WEAPONS) or
            ((slot == "body" or slot == "shield") and
                class == object_classes.OBJ_ARMOUR) or
            (slot == "jewellery" and
                class == object_classes.OBJ_JEWELLERY)

        if active then
            value = value + properties.value(ctx, entry.entity,
                property_id)
        end
    end

    return value
end

-- A dual wielder alternates hands by contact number. Other callers may
-- ask for the actor's current melee weapon without selecting a contact;
-- ordinary monsters never activate an alternate inventory weapon.
function equipment.monster_melee(ctx, monster, contact_index)
    for _, entity in ipairs(ctx:query({ "core.equipped", "core.carried_by" })) do
        local carrier = ctx:get(entity, "core.carried_by")
        local slot = ctx:get(entity, "core.equipped")

        if carrier.holder == monster and slot.slot ~= "weapon" and
            slot.slot ~= "alternate_weapon" and slot.slot ~= "missile" and
            slot.slot ~= "shield" and slot.slot ~= "body" then
            error("monster has unsupported equipment slot " .. slot.slot)
        end
    end

    local worn = equipment.worn(ctx, monster, {
        weapon = true,
        alternate_weapon = true,
    })

    local actor = ctx:get(monster, component.ACTOR)
    local definition = actor and catalog.get("monsters", actor.kind_id)
    local dual = definition and has_flag(definition.flags,
        monster_flags.TWO_WEAPONS)
    local slots = { "weapon" }

    if dual and contact_index and contact_index % 2 == 0 then
        slots = { "alternate_weapon", "weapon" }
    elseif dual and not contact_index then
        slots = { "weapon", "alternate_weapon" }
    end

    for _, slot in ipairs(slots) do
        local entry = worn[slot]

        if entry then
            local definition = entry.definition

            if definition.class ~= "OBJ_WEAPONS" or not definition.weapon then
                error("monster has non-weapon in " .. slot)
            end

            if not has_flag(definition.weapon.damage_flags, "DAMV_NON_MELEE") then
                local properties = require(
                    "policy.item_generation.artefacts.properties")

                return {
                    entity = entry.entity,
                    damage = definition.weapon.damage +
                        properties.value(ctx, entry.entity,
                            artefact_ids.BASE_DAMAGE),
                    hit = definition.weapon.hit +
                        properties.value(ctx, entry.entity,
                            artefact_ids.BASE_ACCURACY),
                    plus = entry.item.plus,
                    brand = entry.ego,
                }
            end
        end
    end

    return nil
end

-- Spectral orcs wear their original armour. Read it through the same
-- validated equipment view used for their weapons and shields.
function equipment.monster_body(ctx, monster)
    local body = equipment.worn(ctx, monster, { body = true }).body

    if body and (body.definition.class ~= "OBJ_ARMOUR" or
        not body.definition.armour or
        body.definition.armour.slot_id ~= "EQ_BODY_ARMOUR") then
        error("monster has non-armour in body slot")
    end

    return body
end

-- Monster shield lookup shares the validated worn snapshot with melee gear.
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

-- Monster AC combines active melee Protection with a corrosion penalty.
function equipment.protection_ac(ctx, monster)
    local weapon = equipment.monster_melee(ctx, monster)
    local body = equipment.monster_body(ctx, monster)
    local bonus = enchant.corroded(ctx, monster) and -8 or 0

    if body then
        bonus = bonus + body.definition.armour.ac + body.item.plus
    end

    if weapon and weapon.brand == "SPWPN_PROTECTION" then
        bonus = bonus + 5
    end

    return bonus
end

return equipment
