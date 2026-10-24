-- Monster resistance is a live actor property. Catalog levels are only
-- the starting point; equipped items and timed effects can change them.
local armour_egos = require("constants.armour_egos")
local armour_flags = require("constants.armour_flags")
local component = require("constants.component")
local construct_components = require("constants.monster_construct_components")
local item_use = require("constants.monster_item_use")
local monster_flags = require("constants.monster_flags")
local jewellery_capabilities = require("constants.jewellery_capabilities")
local holiness = require("constants.monster_holiness")
local artefact_ids = require("ids.artefact_properties")
local unique_ids = require("ids.artefacts")
local item_ids = require("ids.items")
local object_classes = require("ids.object_classes")
local resistances = require("constants.resistance_ids")
local equipment = require("policy.combat.equipment")
local hex_status = require("policy.combat.monster_hexes.status")
local jewellery_effects = require("policy.inventory.jewellery_effects")
local properties = require("policy.item_generation.artefacts.properties")
local staves = require("policy.inventory.staves")

local resistance = {}

local armour_resistance = {
    [resistances.FIRE] = armour_flags.RES_FIRE,
    [resistances.COLD] = armour_flags.RES_COLD,
    [resistances.ELECTRICITY] = armour_flags.RES_ELECTRICITY,
    [resistances.POISON] = armour_flags.RES_POISON,
    [resistances.ACID] = armour_flags.RES_CORROSION,
    [resistances.NEGATIVE_ENERGY] = armour_flags.RES_NEGATIVE_ENERGY,
}

local armour_vulnerability = {
    [resistances.FIRE] = armour_flags.VUL_FIRE,
    [resistances.COLD] = armour_flags.VUL_COLD,
}

local jewellery_resistance = {
    [resistances.FIRE] = jewellery_capabilities.FIRE_RESISTANCE,
    [resistances.COLD] = jewellery_capabilities.COLD_RESISTANCE,
    [resistances.ELECTRICITY] =
        jewellery_capabilities.ELECTRICITY_RESISTANCE,
    [resistances.POISON] = jewellery_capabilities.POISON_RESISTANCE,
    [resistances.ACID] =
        jewellery_capabilities.CORROSION_RESISTANCE,
    [resistances.NEGATIVE_ENERGY] =
        jewellery_capabilities.NEGATIVE_ENERGY_RESISTANCE,
}

local artefact_resistance = {
    [resistances.FIRE] = artefact_ids.FIRE,
    [resistances.COLD] = artefact_ids.COLD,
    [resistances.ELECTRICITY] = artefact_ids.ELECTRICITY,
    [resistances.POISON] = artefact_ids.POISON,
    [resistances.ACID] = artefact_ids.RCORR,
    [resistances.NEGATIVE_ENERGY] = artefact_ids.NEGATIVE_ENERGY,
}

-- The caller supplies the actor's projected profile. Its saved base
-- excludes temporary enchantment so equipment can be added first.
local function intrinsic(definition, resistance_id)
    local base = definition.resistance_base or
        definition.resistances or {}
    local value

    for _, entry in ipairs(base) do
        if entry.id == resistance_id then
            -- Generated monster overlays follow catalog entries, so the
            -- final matching row is the actor's current intrinsic value.
            value = entry.level
        end
    end

    if value ~= nil then
        return value
    end

    if resistance_id == resistances.POISON then
        for _, id in ipairs(definition.holiness or {}) do
            if id == holiness.UNDEAD or id == holiness.NONLIVING then
                return 3
            end
        end
    end

    return 0
end

-- Source ENCH_RESISTANCE is added after gear, poison's intrinsic early
-- return, and fire vulnerability. The profile's projected array keeps
-- older callers working, while its saved base prevents premature caps.
local function enchantment(ctx, monster)
    local state = ctx:get(monster,
        construct_components.RESISTANCE)

    return state and state.remaining_aut > 0 and 1 or 0
end

-- Source negative-energy immunity is based on holiness, regardless of
-- worn items or the numeric resistance in the monster catalog.
local function nonliving(definition)
    for _, id in ipairs(definition.holiness or {}) do
        if id == holiness.NATURAL or id == holiness.PLANT then
            return false
        end
    end

    return #(definition.holiness or {}) > 0
end

-- Read intrinsic armour flags, including the negative aliases used by
-- fire and ice dragon scales, without counting artefact properties here.
local function armour_flag_value(definition, resistance_id)
    local value = 0
    local wanted = armour_resistance[resistance_id]
    local vulnerability = armour_vulnerability[resistance_id]
    local source = definition.armour and definition.armour.flags
    local flags = type(source) == "table" and source or {}

    for _, flag in ipairs(flags) do
        if flag.id == wanted or flag.id == vulnerability then
            value = value + flag.level
        end
    end

    return value
end

-- Source armour egos contribute one step only in their matching element;
-- Reflection and Protection are handled by defense, not resistance.
local function armour_ego_value(ego, resistance_id)
    if resistance_id == resistances.FIRE and
        (ego == armour_egos.RESISTANCE or
            ego == armour_egos.FIRE_RESISTANCE) then
        return 1
    end

    if resistance_id == resistances.COLD and
        (ego == armour_egos.RESISTANCE or
            ego == armour_egos.COLD_RESISTANCE) then
        return 1
    end

    if resistance_id == resistances.POISON and
        ego == armour_egos.POISON_RESISTANCE then
        return 1
    end

    if resistance_id == resistances.NEGATIVE_ENERGY and
        ego == armour_egos.POSITIVE_ENERGY then
        return 1
    end

    return 0
end

-- A monster below the source's starting-equipment item-use level cannot
-- gain resistance from an item even if a mod gives it equipped records.
local function can_use_gear(definition)
    return definition.item_use_id == item_use.STARTING_EQUIPMENT or
        definition.item_use_id == item_use.WEAPONS_ARMOUR
end

-- Only source dual wielders receive artefact properties from their second
-- weapon; other alternate weapons are inventory swaps, not active gear.
local function dual_wields(definition)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == monster_flags.TWO_WEAPONS then
            return true
        end
    end

    return false
end

-- Sum each source-eligible item exactly once. Artefact properties are a
-- separate worn-item scan in DCSS; armour and jewellery helpers omit them.
local function equipped(ctx, monster, definition, resistance_id)
    if not can_use_gear(definition) then
        return 0
    end

    local value = 0
    local worn = equipment.worn(ctx, monster, {
        body = true,
        shield = true,
        jewellery = true,
        weapon = true,
        alternate_weapon = true,
    })

    for slot, entry in pairs(worn) do
        local kind = entry.definition

        if slot ~= "alternate_weapon" or dual_wields(definition) then
            value = value + properties.value(ctx, entry.entity,
                artefact_resistance[resistance_id])
        end

        if (slot == "body" or slot == "shield") and
            kind.class == object_classes.OBJ_ARMOUR then
            if slot == "body" or
                (slot == "shield" and
                    resistance_id ~= resistances.ACID) then
                value = value + armour_flag_value(kind,
                    resistance_id)
            end

            value = value + armour_ego_value(entry.ego, resistance_id)

            if resistance_id == resistances.ACID and
                entry.ego == armour_egos.PRESERVATION then
                value = value + 1
            end

        elseif slot == "jewellery" and
            kind.class == object_classes.OBJ_JEWELLERY then
            local capability = jewellery_resistance[resistance_id]

            if capability then
                value = value + jewellery_effects.value(entry.item,
                    kind, capability)
            end
        elseif slot == "weapon" then
            value = value + staves.resistance(kind, resistance_id)
        end
    end

    return value
end

-- Match the source's ordering: poison has an intrinsic early return,
-- equipment poison is boolean, and elemental caps apply after statuses.
function resistance.level(ctx, monster, definition, resistance_id)
    local value = intrinsic(definition, resistance_id)

    if resistance_id == resistances.MIASMA then
        -- Cigotuvi's Embrace is the one source equipment exception to
        -- intrinsic miasma immunity; its inscription is not a property.
        local body = equipment.worn(ctx, monster,
            { body = true }).body
        local artefact = body and ctx:get(body.entity,
            component.ITEM_ARTEFACT)

        if artefact and artefact.unique_id ==
            unique_ids.UNRAND_EMBRACE then
            return math.max(1, value)
        end

        return value
    end

    if resistance_id == resistances.STEAM then
        local fire = resistance.level(ctx, monster, definition,
            resistances.FIRE)

        value = value + math.modf((fire + 1) / 2)

        -- Source checks wearing body armour directly for rSteam.
        local body = equipment.worn(ctx, monster,
            { body = true }).body

        if body and body.item.kind_id ==
            item_ids.ARM_STEAM_DRAGON_ARMOUR then
            value = value + 3
        end

        return math.min(3, value)
    end

    if resistance_id == resistances.ACID then
        local gear = equipped(ctx, monster, definition,
            resistance_id)

        return math.max(value, gear > 0 and 1 or 0) +
            enchantment(ctx, monster)
    end

    if resistance_id == resistances.NEGATIVE_ENERGY and
        nonliving(definition) then
        return 3
    end

    if resistance_id == resistances.POISON then
        -- Source checks the actively wielded Olgreb artefact before the
        -- ordinary item-use gate and before poison vulnerability.
        local weapon = equipment.worn(ctx, monster,
            { weapon = true }).weapon

        local artefact = weapon and ctx:get(weapon.entity,
            component.ITEM_ARTEFACT)

        if artefact and artefact.unique_id ==
            unique_ids.UNRAND_OLGREB then
            return 3
        end

        if value < 3 and hex_status.poison_vulnerable(ctx, monster) then
            value = value - 1
        end

        if value > 0 then
            return value
        end
    end

    value = value + equipped(ctx, monster, definition, resistance_id)

    if resistance_id == resistances.FIRE then
        local vulnerability = ctx:get(monster,
            component.FIRE_VULNERABILITY)

        if vulnerability and vulnerability.remaining_aut > 0 then
            value = value - 1
        end
    end

    if resistance_id == resistances.POISON then
        return math.min(1, value + enchantment(ctx, monster))
    end

    if resistance_id == resistances.ELECTRICITY then
        return value + enchantment(ctx, monster)
    end

    if resistance_id == resistances.NEGATIVE_ENERGY then
        return math.min(3, value)
    end

    if resistance_id == resistances.FIRE or
        resistance_id == resistances.COLD then
        value = value + enchantment(ctx, monster)
    end

    return math.max(-3, math.min(3, value))
end

return resistance
