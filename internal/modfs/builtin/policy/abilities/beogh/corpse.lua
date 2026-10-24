-- Orc corpses retain a compact saved monster snapshot for Resurrection.
-- Ordinary corpse decay and item placement stay with the death owner.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local gift_categories = require("constants.beogh_gift_categories")
local armour_slots = require("constants.armour_slots")
local monsters = require("ids.monsters")
local monster_slots = require("constants.monster_equipment_slots")
local monster_stats = require("policy.combat.monster_stats")
local object_classes = require("ids.object_classes")

local corpse = {}

-- The source puts a resurrection record on every ordinary orc corpse,
-- including an enemy that Beogh has not yet converted.
function corpse.record(ctx, dead, body, dropped)
    if not body then
        return
    end

    local actor = ctx:get(dead, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    if definition.genus_id ~= monsters.MONS_ORC then
        return
    end

    local health = ctx:get(dead, component.HEALTH)
    local authored = ctx:get(dead, component.VAULT_ACTOR_OVERRIDES)
    local allegiance = ctx:get(dead, component.BEOGH_ORC)
    local gear = {}

    for _, entry in ipairs(dropped or {}) do
        if entry.slot then
            gear[entry.slot] = ctx:id(entry.entity)
        end
    end

    ctx:add(body, component.BEOGH_CORPSE, {
        kind_id = actor.kind_id,
        max_hp = health.max,
        speed = actor.speed,
        hit_dice = monster_stats.base_hit_dice(ctx, dead, definition),
        custom_name = authored and authored.custom_name or "",
        name_adjective = authored and authored.name_adjective or false,
        gift_category = allegiance and allegiance.gift_category or "",
        dropped_gear = gear,
    })
end

-- A remembered slot must fit its extant item before a later resurrection
-- can reclaim it. Missing IDs are allowed because gear may be destroyed.
local function gear_fits(ctx, slot, id)
    local entity = ctx:entity(id)
    local item = entity and ctx:get(entity, component.ITEM)

    if not item then
        return true
    end

    local kind = catalog.get(categories.ITEMS, item.kind_id)

    if slot == monster_slots.WEAPON or
        slot == monster_slots.ALTERNATE_WEAPON then
        return kind.class == object_classes.OBJ_WEAPONS and
            kind.weapon ~= nil
    end

    if slot == monster_slots.MISSILE then
        return kind.class == object_classes.OBJ_MISSILES and
            kind.missile ~= nil
    end

    if slot == monster_slots.SHIELD then
        return kind.class == object_classes.OBJ_ARMOUR and
            kind.armour ~= nil and
            kind.armour.slot_id == armour_slots.SHIELD
    end

    return slot == monster_slots.BODY and
        kind.class == object_classes.OBJ_ARMOUR and
        kind.armour ~= nil and
        kind.armour.slot_id == armour_slots.BODY_ARMOUR
end

-- The saved Beogh actor is the Orc body at death, which may differ from the
-- corpse's pre-polymorph species. Gear may disappear after death.
function corpse.validate(ctx, body)
    local state = ctx:get(body, component.BEOGH_CORPSE)

    if not state then
        return
    end

    local ordinary = ctx:get(body, component.CORPSE)
    local actor = catalog.get(categories.MONSTERS, state.kind_id)
    local death_id = ordinary and ordinary.death_kind_id ~= "" and
        ordinary.death_kind_id or ordinary and ordinary.monster_id

    if not ordinary or death_id ~= state.kind_id or
        actor.genus_id ~= monsters.MONS_ORC or
        state.max_hp < 1 or state.max_hp > 10000 or
        state.speed < 1 or state.speed > 100 or
        state.hit_dice < 1 or state.hit_dice > 100 or
        (state.gift_category ~= "" and
            not gift_categories.valid(state.gift_category)) then
        error("invalid saved Beogh orc corpse " .. ctx:id(body))
    end

    for slot, id in pairs(state.dropped_gear) do
        if not monster_slots.valid(slot) or
            type(id) ~= "number" or id <= 0 or
            not gear_fits(ctx, slot, id) then
            error("invalid saved Beogh dropped gear")
        end
    end
end

return corpse
