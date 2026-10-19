local catalog = require("policy.catalog")
local items = require("policy.inventory.items")
local enchant = require("policy.combat.monster_enchant")
local forms = require("policy.magic.effects.forms.player")
local component = require("constants.component")
local artefact_ids = require("ids.artefact_properties")
local armour_egos = require("constants.armour_egos")
local armour_flags = require("constants.armour_flags")
local jewellery_capabilities = require("constants.jewellery_capabilities")
local jewellery_effects = require("policy.inventory.jewellery_effects")
local jewellery_slots = require("constants.jewellery_slots")
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

-- Monster weapon selection reads the validated equipped-item snapshot rather than raw inventory.
function equipment.monster_melee(ctx, monster)
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

    for _, slot in ipairs({ "weapon", "alternate_weapon" }) do
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

-- Source actor::res_corr includes worn rings, acid dragon body armour,
-- artefact rCorr, and preservation ego. The monster's intrinsic rAcid is
-- checked by its caller, so this answers only the equipped part.
function equipment.monster_res_corr(ctx, monster)
    local slots = {
        weapon = true,
        alternate_weapon = true,
        body = true,
        cloak = true,
        head = true,
        gloves = true,
        boots = true,
        shield = true,
        [jewellery_slots.LEFT] = true,
        [jewellery_slots.RIGHT] = true,
        [jewellery_slots.AMULET] = true,
    }

    for _, slot in ipairs(jewellery_slots.OCTO) do
        slots[slot] = true
    end

    -- The artefact property reader imports equipment for other callers.
    -- Load it after this module has finished registering its methods.
    local properties = require("policy.item_generation.artefacts.properties")

    for slot, entry in pairs(equipment.worn(ctx, monster, slots)) do
        if properties.value(ctx, entry.entity,
            artefact_ids.RCORR) > 0 then
            return true
        end

        local definition = entry.definition

        if definition.class == object_classes.OBJ_JEWELLERY and
            jewellery_effects.value(entry.item, definition,
                jewellery_capabilities.CORROSION_RESISTANCE) > 0 then
            return true
        end

        if definition.class == object_classes.OBJ_ARMOUR then
            if entry.ego == armour_egos.PRESERVATION then
                return true
            end

            if slot == "body" and definition.armour then
                for _, flag in ipairs(definition.armour.flags or {}) do
                    if flag.id == armour_flags.RES_CORROSION and
                        flag.level > 0 then
                        return true
                    end
                end
            end
        end
    end

    return false
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
