-- Monster willpower belongs to the live actor. Catalog willpower is only
-- the base; gear, damage to HD, and active magic can change the next save.
local armour_egos = require("constants.armour_egos")
local armour_flags = require("constants.armour_flags")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local item_use = require("constants.monster_item_use")
local jewellery_capabilities = require("constants.jewellery_capabilities")
local monster_flags = require("constants.monster_flags")
local artefact_ids = require("ids.artefact_properties")
local object_classes = require("ids.object_classes")
local unique_ids = require("ids.artefacts")
local units = require("constants.willpower")
local equipment = require("policy.combat.equipment")
local jewellery_effects = require("policy.inventory.jewellery_effects")
local monster_profile = require("policy.combat.monster_profile")
local monster_stats = require("policy.combat.monster_stats")
local draconian_base = require("policy.monsters.draconian_base")
local properties = require("policy.item_generation.artefacts.properties")
local trogs_hand = require("policy.combat.monster_support.trogs_hand")

local willpower = {}

-- Monster flags describe ancestor and dual-weapon behavior independently
-- of their dynamic HD and current equipment.
local function has_flag(definition, wanted)
    for _, id in ipairs(definition.flags or {}) do
        if id == wanted then
            return true
        end
    end

    return false
end

-- Source scans only an active item of the expected class at each slot.
local function artefact_slot_active(slot, entry, definition)
    local class = entry.definition.class

    if slot == "weapon" then
        return class == object_classes.OBJ_WEAPONS
    end

    if slot == "alternate_weapon" then
        return class == object_classes.OBJ_WEAPONS and
            has_flag(definition, monster_flags.TWO_WEAPONS)
    end

    if slot == "body" or slot == "shield" then
        return class == object_classes.OBJ_ARMOUR
    end

    return slot == "jewellery" and
        class == object_classes.OBJ_JEWELLERY
end

-- The source scans artefacts only on item-using monsters and counts the
-- second weapon only when it is active for a dual wielder.
local function artefact_pips(ctx, definition, worn)
    if definition.item_use_id ~= item_use.STARTING_EQUIPMENT and
        definition.item_use_id ~= item_use.WEAPONS_ARMOUR then
        return 0
    end

    local total = 0

    for slot, entry in pairs(worn) do
        if artefact_slot_active(slot, entry, definition) then
            total = total + properties.value(ctx, entry.entity,
                artefact_ids.WILLPOWER)
        end
    end

    return total
end

-- Body and shield kind flags and egos contribute without artefact
-- properties, which the separate source scan already counted.
local function armour_pips(entry)
    local total = 0
    local armour = entry.definition.armour
    local source = armour and armour.flags
    local flags = type(source) == "table" and source or {}

    for _, flag in ipairs(flags) do
        if flag.id == armour_flags.WILLPOWER then
            total = total + flag.level
        end
    end

    if entry.ego == armour_egos.WILLPOWER then
        total = total + 1
    elseif entry.ego == armour_egos.GUILE then
        total = total - 2
    end

    return total
end

-- Negative catalog values scale by current HD. Drain and Wretched then
-- proportionally reduce the species base against its unmodified HD.
local function base(ctx, monster, definition)
    local current_hd = monster_stats.hit_dice(ctx, monster,
        definition)
    local original_hd = monster_stats.base_hit_dice(ctx, monster,
        definition)
    local catalogued = definition.willpower or 0
    local value

    -- Draconian jobs borrow intrinsic will from their saved colour. Their
    -- job row controls HD, so only the willpower source row changes here.
    if catalogued >= 0 and draconian_base.is_job(definition.id) then
        local saved = ctx:get(monster, component.MONSTER_DRACONIAN_BASE)
        local color_id = draconian_base.for_job(definition.id,
            saved and saved.base_id)

        catalogued = catalog.get(categories.MONSTERS,
            color_id).willpower
    end

    if has_flag(definition, monster_flags.ANCESTOR) then
        value = math.floor(original_hd * original_hd / 2)
    elseif catalogued < 0 then
        value = math.floor(current_hd * -catalogued * 4 / 3)
    else
        value = catalogued
    end

    if current_hd < original_hd then
        value = math.floor(value * current_hd / original_hd)
    end

    return value
end

-- Use the source order: invulnerability, Folly, scaled body, worn pips,
-- Trog's Hand, Lowered Will, then the nonnegative floor.
function willpower.level(ctx, monster, definition)
    definition = monster_profile.definition(ctx, monster, definition)

    if (definition.willpower or 0) >= units.INVULNERABLE then
        return units.INVULNERABLE
    end

    local worn = equipment.worn(ctx, monster, {
        weapon = true,
        alternate_weapon = true,
        body = true,
        shield = true,
        jewellery = true,
    })
    local body = worn.body
    local artefact = body and ctx:get(body.entity,
        component.ITEM_ARTEFACT)

    if artefact and artefact.unique_id == unique_ids.UNRAND_FOLLY then
        return 0
    end

    local value = base(ctx, monster, definition) +
        units.PIP * artefact_pips(ctx, definition, worn)

    for _, slot in ipairs({ "body", "shield" }) do
        local entry = worn[slot]

        if entry and entry.definition.class ==
            object_classes.OBJ_ARMOUR then
            value = value + units.PIP * armour_pips(entry)
        end
    end

    local ring = worn.jewellery

    if ring and ring.definition.class ==
        object_classes.OBJ_JEWELLERY then
        value = value + units.PIP * jewellery_effects.value(ring.item,
            ring.definition,
            jewellery_capabilities.WILLPOWER_PIPS)
    end

    value = value + trogs_hand.will_bonus(ctx, monster)

    local lowered = ctx:get(monster, component.MONSTER_LOWERED_WILL)

    if lowered and lowered.remaining_aut > 0 then
        value = math.floor(value / 2)
    end

    return math.max(0, value)
end

return willpower
