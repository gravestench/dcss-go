-- Xom upgrades a hostile's existing equipment in place. The item owns its
-- brand and enchantment, so later attacks, drops, pickup, and saves all see
-- the same changed object without an Xom-specific combat adapter.
local ai_behaviors = require("constants.ai_behaviors")
local artefact_kinds = require("constants.artefact_kinds")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local confusion = require("policy.religion.xom.confusion")
local equipment = require("policy.combat.equipment")
local events = require("ids.xom_events")
local gods = require("constants.gods")
local alignments = require("policy.religion.alignments")
local holiness = require("constants.monster_holiness")
local item_use = require("constants.monster_item_use")
local items = require("ids.items")
local missile_egos = require("constants.missile_egos")
local monsters = require("ids.monsters")
local spellbooks = require("ids.monster_spellbooks")
local spell_flags = require("constants.monster_spell_flags")
local object_classes = require("ids.object_classes")
local slots = require("constants.monster_equipment_slots")
local streams = require("constants.rng_streams")
local weapon_brands = require("constants.weapon_brands")
local brand_pool = require("policy.inventory.brand_pool")

local effect = {}

local slot_order = {
    slots.WEAPON,
    slots.ALTERNATE_WEAPON,
    slots.MISSILE,
}

local launcher_slots = {
    slots.WEAPON,
    slots.ALTERNATE_WEAPON,
}

-- A catalog trait, rather than the species name, identifies holy monsters.
local function has_holiness(definition, wanted)
    for _, value in ipairs(definition.holiness or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- DES god annotations and normal worship use the same god catalog. A
-- holy creature without a chaotic patron is protected from this upgrade.
local function protected_by_god(ctx, monster, definition)
    local override = ctx:get(monster, component.VAULT_ACTOR_OVERRIDES)
    local worship = ctx:get(monster, component.RELIGION_WORSHIP)
    local god_id = override and override.god_id or
        worship and worship.god_id or gods.NO_GOD

    if god_id == "" then
        god_id = gods.NO_GOD
    end

    if alignments.good(god_id) then
        return true
    end

    if has_holiness(definition, holiness.HOLY) and
        not alignments.chaotic(god_id) then
        return true
    end

    return false
end

-- Orc priests are protected by Beogh regardless of their equipment. Read
-- their actual spell slot flags, so a new priest book inherits this rule.
local function orc_priest(definition)
    if definition.genus_id ~= monsters.MONS_ORC or
        not definition.spellbook_id or
        definition.spellbook_id == spellbooks.MST_NO_SPELLS or
        definition.spellbook_id == spellbooks.MST_GHOST then
        return false
    end

    local book = catalog.get(categories.MONSTER_SPELLBOOKS,
        definition.spellbook_id)

    for _, slot in ipairs(book.slots or {}) do
        for _, flag in ipairs(slot.flags or {}) do
            if flag == spell_flags.PRIEST then
                return true
            end
        end
    end

    return false
end

-- A flaming, freezing, or venomous launcher overrides its own ammunition
-- brand. A monster may still throw a different missile by hand, so that
-- separate stack remains eligible for Xom.
local function launcher_supersedes_ammo(worn, missile)
    for _, slot in ipairs(launcher_slots) do
        local launcher = worn[slot]
        local weapon = launcher and launcher.definition.weapon
        local brand = launcher and launcher.ego

        if weapon and weapon.ammo_id == missile.definition.id and
            (brand == weapon_brands.FLAMING or
                brand == weapon_brands.FREEZING or
                brand == weapon_brands.VENOM) then
            return true
        end
    end

    return false
end

-- The source will not rewrite a unique artefact, a blessed weapon, a
-- summoned monster's temporary gear, or a gift from another god.
local function upgradeable(ctx, monster, entry)
    local item = entry.item
    local definition = entry.definition
    local artefact = ctx:get(entry.entity, component.ITEM_ARTEFACT)
    local provenance = ctx:get(entry.entity, component.ITEM_PROVENANCE)

    if artefact and artefact.kind == artefact_kinds.UNIQUE then
        return false
    end

    if ctx:has(monster, component.SUMMON) or
        provenance and provenance.god_id ~= "" and
            provenance.god_id ~= gods.XOM then
        return false
    end

    if definition.class == object_classes.OBJ_WEAPONS then
        return definition.weapon ~= nil and
            brand_pool.eligible(definition) and
            (entry.ego == "" or
                entry.ego == weapon_brands.NORMAL)
    end

    if definition.class == object_classes.OBJ_MISSILES then
        return definition.id ~= items.MI_LARGE_ROCK and
            definition.id ~= items.MI_THROWING_NET and
            entry.ego == ""
    end

    return false
end

-- Source eligibility rejects an already-chaotic loadout before deciding
-- which otherwise eligible slot gets the upgrade.
local function upgrade_item(ctx, monster, definition, stream)
    if definition.item_use_id ~= item_use.STARTING_EQUIPMENT and
        definition.item_use_id ~= item_use.WEAPONS_ARMOUR then
        return nil
    end

    if protected_by_god(ctx, monster, definition) then
        return nil
    end

    -- Source rejects every orc priest. Other orcs pass only a coinflip;
    -- choosing the monster and choosing its gear remain separate draws.
    if definition.genus_id == monsters.MONS_ORC and
        (orc_priest(definition) or
            ctx:random(stream, 2) == 0) then
        return nil
    end

    local worn = equipment.worn(ctx, monster, {
        [slots.WEAPON] = true,
        [slots.ALTERNATE_WEAPON] = true,
        [slots.MISSILE] = true,
    })
    local chosen

    for _, slot in ipairs(slot_order) do
        local entry = worn[slot]

        if entry then
            if entry.ego == weapon_brands.CHAOS or
                entry.ego == missile_egos.CHAOS then
                return nil
            end

            if not chosen and upgradeable(ctx, monster, entry) and
                (slot ~= slots.MISSILE or
                    not launcher_supersedes_ammo(worn, entry)) then
                chosen = entry
            end
        end
    end

    return chosen
end

-- Selection and execution share the same candidate rule so a failed
-- source exclusion does not consume an action before another valid target.
function effect.candidates(ctx, player, stream)
    stream = stream or streams.RELIGION
    local candidates = {}

    for _, monster in ipairs(confusion.nearby(ctx, player)) do
        if confusion.hostile(ctx, monster) then
            local actor = ctx:get(monster, component.ACTOR)
            local definition = actor and catalog.get("monsters",
                actor.kind_id)
            local item = definition and upgrade_item(ctx, monster,
                definition, stream)

            if item then
                candidates[#candidates + 1] = {
                    monster = monster,
                    item = item,
                }
            end
        end
    end

    return candidates
end

-- Ordinary weapons gain up to four enchantment points; a random artefact
-- keeps its generated properties and changes only its mutable brand field.
local function brand_item(ctx, entry, stream)
    local artefact = ctx:get(entry.entity, component.ITEM_ARTEFACT)
    local weapon = entry.definition.class == object_classes.OBJ_WEAPONS
    local brand = weapon and weapon_brands.CHAOS or missile_egos.CHAOS

    if artefact and artefact.kind == artefact_kinds.RANDOM then
        artefact.brand = brand
        ctx:set(entry.entity, component.ITEM_ARTEFACT, artefact)
        return
    end

    local item = entry.item

    item.ego = brand

    if weapon then
        item.plus = item.plus + ctx:random(stream, 5)
    end

    ctx:set(entry.entity, component.ITEM, item)
end

-- Wake the selected monster as in the source behavior event; the next AI
-- turn can then wield or throw the upgraded item normally.
function effect.apply(ctx, player, event_id, _, request)
    if event_id ~= events.BAD_CHAOS_UPGRADE then
        error("chaos upgrade received another Xom event")
    end

    local stream = request and request.stream or streams.RELIGION
    local candidates = effect.candidates(ctx, player, stream)

    if #candidates == 0 then
        return false
    end

    local chosen = candidates[ctx:random(stream, #candidates) + 1]

    brand_item(ctx, chosen.item, stream)

    local ai = ctx:get(chosen.monster, component.AI)

    if ai and ai.behavior == ai_behaviors.SLEEP then
        ai.behavior = ai_behaviors.WANDER
        ctx:set(chosen.monster, component.AI, ai)
    end

    ctx:emit("religion", "Xom upgrades a monster's equipment with chaos!")

    return true
end

return effect
