-- Monsters have one body-armour inventory slot. Source pickup rules map
-- some cloaks and hats onto it for species that cannot wear body suits.
local armour_slots = require("constants.armour_slots")
local catalog = require("policy.catalog")
local component = require("constants.component")
local item_ids = require("ids.items")
local monsters = require("ids.monsters")
local object_classes = require("ids.object_classes")

local armour = {}

local cloak_wearers = {
    [monsters.MONS_MAURICE] = true,
    [monsters.MONS_NIKOLA] = true,
    [monsters.MONS_CRAZY_YIUF] = true,
}

-- Resolve the live species before validating a body's item. Source
-- pickup_armour treats every draconian cloak as body armour while barring
-- ordinary body armour on draconians, octopodes, and Gastronok.
function armour.wears_body(ctx, monster, kind)
    if kind.class ~= object_classes.OBJ_ARMOUR or
        not kind.armour then
        return false
    end

    local actor = ctx:get(monster, component.ACTOR)
    local definition = actor and catalog.get("monsters", actor.kind_id)
    local draconian = definition and
        definition.genus_id == monsters.MONS_DRACONIAN
    local octopode = definition and
        definition.genus_id == monsters.MONS_OCTOPODE
    local gastronok = actor and
        actor.kind_id == monsters.MONS_GASTRONOK
    local slot = kind.armour.slot_id

    if slot == armour_slots.BODY_ARMOUR then
        return not draconian and not octopode and not gastronok
    end

    if slot == armour_slots.CLOAK then
        return draconian or
            (actor and cloak_wearers[actor.kind_id]) or false
    end

    -- Source maps a hat, specifically, into the single monster body slot
    -- for Gastronok and octopodes. A helmet is still a different item.
    if slot == armour_slots.HELMET and
        kind.id == item_ids.ARM_HAT then
        return gastronok or octopode or false
    end

    return false
end

return armour
