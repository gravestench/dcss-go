local classes = require("ids.object_classes")
local ids = require("ids.items")
local jewellery_kind = require("constants.jewellery_kind")
local properties = require("ids.artefact_properties")
local skills = require("ids.skills")
local brands = require("constants.weapon_brands")

local rules = {}

local intrinsic = {
    [ids.RING_PROTECTION] = properties.AC,
    [ids.RING_FIRE] = properties.FIRE,
    [ids.RING_PROTECTION_FROM_FIRE] = properties.FIRE,
    [ids.RING_POISON_RESISTANCE] = properties.POISON,
    [ids.RING_ICE] = properties.COLD,
    [ids.RING_PROTECTION_FROM_COLD] = properties.COLD,
    [ids.RING_STRENGTH] = properties.STRENGTH,
    [ids.RING_SLAYING] = properties.SLAYING,
    [ids.RING_SEE_INVISIBLE] = properties.SEE_INVISIBLE,
    [ids.RING_STEALTH] = properties.STEALTH,
    [ids.RING_EVASION] = properties.EVASION,
    [ids.RING_DEXTERITY] = properties.DEXTERITY,
    [ids.RING_INTELLIGENCE] = properties.INTELLIGENCE,
    [ids.RING_MAGICAL_POWER] = properties.MAGICAL_POWER,
    [ids.RING_FLIGHT] = properties.FLY,
    [ids.RING_LIFE_PROTECTION] = properties.NEGATIVE_ENERGY,
    [ids.RING_WILLPOWER] = properties.WILLPOWER,
    [ids.RING_RESIST_CORROSION] = properties.RCORR,
    [ids.AMU_REGENERATION] = properties.REGENERATION,
    [ids.AMU_REFLECTION] = properties.SHIELDING,
}

local function amulet(definition)
    return definition.jewellery and
        definition.jewellery.kind == jewellery_kind.AMULET
end

local function non_swappable(definition)
    return definition.class == classes.OBJ_ARMOUR or amulet(definition)
end

local function ranged(definition)
    return definition.weapon and
        definition.weapon.skill_id == skills.SK_RANGED_WEAPONS
end

function rules.compatible(id, definition, values, brand)
    -- Source: crawl-ref/source/artefact.cc:529-613.
    if intrinsic[definition.id] == id then
        return false
    end

    if id == properties.SLAYING then
        return definition.class ~= classes.OBJ_WEAPONS
    elseif id == properties.SEE_INVISIBLE then
        return definition.id ~= ids.ARM_BARDING
    elseif id == properties.RAMPAGING then
        return non_swappable(definition) and
            definition.id ~= ids.ARM_BARDING
    elseif id == properties.CORRODE then
        return not values[properties.RCORR]
    elseif id == properties.RCORR then
        return not values[properties.CORRODE]
    elseif id == properties.MAGICAL_POWER then
        return definition.class ~= classes.OBJ_WEAPONS or
            brand ~= brands.ANTIMAGIC
    elseif id == properties.BLINK then
        return not values[properties.PREVENT_TELEPORTATION]
    elseif id == properties.PREVENT_TELEPORTATION then
        return not values[properties.BLINK] and
            non_swappable(definition)
    elseif id == properties.ANGRY or id == properties.NOISE then
        return definition.class == classes.OBJ_WEAPONS and
            not ranged(definition)
    elseif id == properties.PREVENT_SPELLCASTING then
        return definition.id ~= ids.AMU_MANA_REGENERATION and
            non_swappable(definition)
    elseif id == properties.REGENERATION or
        id == properties.HARM or
        id == properties.INVISIBLE then
        return non_swappable(definition)
    elseif id == properties.FRAGILE then
        return definition.class ~= classes.OBJ_ARMOUR and
            (definition.class ~= classes.OBJ_JEWELLERY or
                amulet(definition))
    elseif id == properties.ARCHMAGI then
        return definition.id == ids.ARM_ROBE
    end

    return true
end

function rules.bad(definition, values, brand)
    -- Source: crawl-ref/source/artefact.cc:1475-1629.
    local count = 0

    for _ in pairs(values) do
        count = count + 1
    end

    if count == 0 then
        return true
    end

    if definition.class == classes.OBJ_WEAPONS and
        (brand == "" or count < 1) then
        return true
    end

    if intrinsic[definition.id] and values[intrinsic[definition.id]] then
        return true
    end

    if values[properties.PREVENT_SPELLCASTING] and
        ((values[properties.INTELLIGENCE] or 0) > 0 or
            (values[properties.MAGICAL_POWER] or 0) > 0 or
            values[properties.ARCHMAGI]) then
        return true
    end

    if definition.id == ids.RING_WIZARDRY and
        (values[properties.INTELLIGENCE] or 0) < 0 then
        return true
    end

    return false
end

return rules
