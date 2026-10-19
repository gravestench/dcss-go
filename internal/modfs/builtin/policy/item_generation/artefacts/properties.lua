local component = require("constants.component")
local equipment = require("policy.combat.equipment")
local ids = require("ids.artefact_properties")
local slots = require("constants.jewellery_slots")
local kinds = require("constants.artefact_kinds")

local properties = {}

local unique_fields = {
    ac = ids.AC,
    ev = ids.EVASION,
    str = ids.STRENGTH,
    int = ids.INTELLIGENCE,
    dex = ids.DEXTERITY,
    fire = ids.FIRE,
    cold = ids.COLD,
    life = ids.NEGATIVE_ENERGY,
    will = ids.WILLPOWER,
    hp = ids.HP,
    mp = ids.MAGICAL_POWER,
    regen = ids.REGENERATION,
    slay = ids.SLAYING,
    stealth = ids.STEALTH,
    angry = ids.ANGRY,
    sh = ids.SHIELDING,
    base_dam = ids.BASE_DAMAGE,
    base_acc = ids.BASE_ACCURACY,
    base_delay = ids.BASE_DELAY,
}

local unique_flags = {
    elec = ids.ELECTRICITY,
    poison = ids.POISON,
    seeinv = ids.SEE_INVISIBLE,
    inv = ids.INVISIBLE,
    fly = ids.FLY,
    clarity = ids.CLARITY,
    nospell = ids.PREVENT_SPELLCASTING,
    notelep = ids.PREVENT_TELEPORTATION,
    corrode = ids.CORRODE,
    drain = ids.DRAIN,
    slow = ids.SLOW,
    rCorr = ids.RCORR,
    harm = ids.HARM,
    rampage = ids.RAMPAGING,
    archmagi = ids.ARCHMAGI,
}

local worn_slots = {
    weapon = true,
    body = true,
    cloak = true,
    head = true,
    gloves = true,
    boots = true,
    shield = true,
    [slots.LEFT] = true,
    [slots.RIGHT] = true,
    [slots.AMULET] = true,
}

for _, slot in ipairs(slots.OCTO) do
    worn_slots[slot] = true
end

-- Property reads use saved source IDs; equipped bonuses are summed only over worn artefacts.
function properties.of(ctx, entity)
    local artefact = ctx:get(entity, component.ITEM_ARTEFACT)

    if not artefact then
        return {}
    end

    if artefact.kind == kinds.RANDOM then
        return artefact.properties
    end

    local result = {}

    for field, value in pairs(artefact.properties) do
        local id = unique_fields[field]

        if id then
            result[id] = value
        end
    end

    for _, flag in ipairs(artefact.flags) do
        local id = unique_flags[flag]

        if id then
            result[id] = 1
        end
    end

    return result
end

-- Example: properties.value(ctx, ring, property_ids.FIRE) reads its effective artefact resistance.
-- Missing properties read as zero so combat and display can use one lookup for random and unique artefacts.
function properties.value(ctx, entity, id)
    return properties.of(ctx, entity)[id] or 0
end

-- Only active equipment slots contribute artefact property totals.
function properties.sum_worn(ctx, player, id)
    local total = 0

    for _, entry in pairs(equipment.worn(ctx, player, worn_slots)) do
        total = total + properties.value(ctx, entry.entity, id)
    end

    return total
end

return properties
