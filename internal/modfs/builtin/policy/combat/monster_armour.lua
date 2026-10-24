-- Monsters have one body-armour inventory slot, but source pickup rules
-- deliberately map cloaks onto it for draconians and three named monsters.
local armour_slots = require("constants.armour_slots")
local catalog = require("policy.catalog")
local component = require("constants.component")
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
-- ordinary body armour on that genus; the named exceptions do likewise.
function armour.wears_body(ctx, monster, kind)
    if kind.class ~= object_classes.OBJ_ARMOUR or
        not kind.armour then
        return false
    end

    local actor = ctx:get(monster, component.ACTOR)
    local definition = actor and catalog.get("monsters", actor.kind_id)
    local draconian = definition and
        definition.genus_id == monsters.MONS_DRACONIAN
    local slot = kind.armour.slot_id

    if slot == armour_slots.BODY_ARMOUR then
        return not draconian
    end

    if slot == armour_slots.CLOAK then
        return draconian or
            (actor and cloak_wearers[actor.kind_id]) or false
    end

    return false
end

return armour
