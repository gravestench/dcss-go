local items = require("policy.inventory.items")
local identification = require("policy.items.identification")
local catalog = require("policy.catalog")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local mutation_effects = require("policy.mutations.effects.registry")
local mutation_capabilities = require("constants.mutation_capabilities")
local staves = require("policy.inventory.staves")
local jewellery = require("policy.inventory.jewellery")
local jewellery_kinds = require("constants.jewellery_kind")
local attunement = require("policy.jewellery.attunement")
local acrobat = require("policy.jewellery.acrobat")
local jewellery_slots = require("constants.jewellery_slots")
local phases = require("constants.equipment_phases")

local equipment = {}

local sizes = {
    SIZE_TINY = 0,
    SIZE_LITTLE = 1,
    SIZE_SMALL = 2,
    SIZE_MEDIUM = 3,
    SIZE_LARGE = 4,
    SIZE_GIANT = 5,
    NUM_SIZE_LEVELS = 6,
}

local supported_weapons = {
    SK_SHORT_BLADES = true,
    SK_LONG_BLADES = true,
    SK_MACES_FLAILS = true,
    SK_AXES = true,
    SK_POLEARMS = true,
    SK_RANGED_WEAPONS = true,
    SK_THROWING = true,
    SK_STAVES = true,
}

-- Gate commands on combat skills the current resolver can execute; a
-- catalogued weapon alone is not evidence that its attack path exists.
-- Example: equipment.weapon_supported(weapon.skill_id).
function equipment.weapon_supported(skill_id)
    return supported_weapons[skill_id] == true
end

local armour_slots = {
    body = true,
    shield = true,
    head = true,
    cloak = true,
    gloves = true,
    boots = true,
}

-- Convert source size IDs to ordered ranks before comparing fit ranges;
-- lexical string comparison would put the sizes in the wrong order.
local function rank(id)
    local value = sizes[id]

    if not value then
        error("unknown source size " .. tostring(id))
    end

    return value
end

-- Species flags are an array in content, so check membership explicitly
-- instead of treating the array as a set keyed by flag name.
local function has_flag(species, id)
    for _, flag in ipairs(species.flags or {}) do
        if flag == id then
            return true
        end
    end

    return false
end

-- Combine anatomy, mutation, and armour fit rules before starting a delayed
-- wear action. Rejecting here prevents a queued action that can never finish.
-- Example: equipment.can_wear(ctx, player, species, helmet_definition).
function equipment.can_wear(ctx, actor, species, kind)
    -- Effective level includes suppression, which matters for whether the
    -- body part currently blocks a slot.
    local function mutation_level(id)
        return mutation_levels.effective(ctx, actor, id)
    end

    if kind.class ~= "OBJ_ARMOUR" or not kind.armour or
        mutation_effects.sum(ctx, actor,
            mutation_capabilities.ARMOUR_USE_FORBIDDEN) > 0 then
        return false
    end

    if species.id == "SP_OCTOPODE" and kind.slot ~= "head" and
        kind.slot ~= "shield" then
        return false
    end

    if species.id:find("^SP_.*DRACONIAN") and kind.slot == "body" then
        return false
    end

    if kind.slot == "shield" and
        mutation_level(mutations.MUT_MISSING_HAND) > 0 then
        return false
    end

    if kind.slot == "gloves" and
        (mutation_level(mutations.MUT_CLAWS) >= 3 or
            mutation_level(mutations.MUT_DEMONIC_TOUCH) >= 3) then
        return false
    end

    if kind.slot == "boots" and
        (has_flag(species, "SPF_BARDING") or
            mutation_level(mutations.MUT_FLOAT) > 0 or
            mutation_level(mutations.MUT_CONSTRICTING_TAIL) > 0 or
            mutation_level(mutations.MUT_PAWS) > 0 or
            mutation_level(mutations.MUT_TENTACLE_ARMS) > 0 or
            mutation_level(mutations.MUT_HOOVES) >= 3 or
            mutation_level(mutations.MUT_TALONS) >= 3) then
        return false
    end

    if kind.slot == "cloak" and
        mutation_level(mutations.MUT_WEAKNESS_STINGER) >= 3 then
        return false
    end

    if kind.slot == "head" then
        local horns = mutation_level(mutations.MUT_HORNS)
        local antennae = mutation_level(mutations.MUT_ANTENNAE)

        if horns >= 3 or antennae >= 3 then
            return false
        end

        if kind.id == "ARM_HELMET" and
            (horns > 0 or antennae > 0 or species.id == "SP_OCTOPODE" or
                mutation_level(mutations.MUT_BEAK) > 0 or
                species.id:find("^SP_.*DRACONIAN")) then
            return false
        end
    end

    return rank(species.size) >= rank(kind.armour.fit_min_id) and
        rank(species.size) <= rank(kind.armour.fit_max_id)
end

-- Search equipped items carried by this actor, not all items with the slot
-- tag. Duplicate weapons indicate broken equipment state and fail loudly.
function equipment.in_slot(ctx, actor, slot)
    local found

    for _, entity in ipairs(ctx:query({ "core.equipped", "core.carried_by" })) do
        local equipped = ctx:get(entity, "core.equipped")
        local carrier = ctx:get(entity, "core.carried_by")

        if carrier.holder == actor and equipped.slot == slot then
            if found and slot == "weapon" then
                error("player has multiple equipped weapons")
            end

            found = found or entity
        end
    end

    return found
end

-- Compare the weapon's one-hand size threshold with the current species;
-- Quadrumanous can free a hand for weapons within its documented limit.
function equipment.needs_second_hand(ctx, actor, kind, species)
    local weapon = staves.weapon(kind)

    if mutation_levels.effective(ctx, actor,
        mutations.MUT_QUADRUMANOUS) > 0 and
        rank(weapon.min_2h_size_id) <= rank("SIZE_MEDIUM") then
        return false
    end

    return rank(species.size) < rank(weapon.min_1h_size_id)
end

-- A prepared result gives the command bridge a free message or an intent and
-- cost. Species definitions come from the committed source catalog.
-- Example: equipment.prepare_wield(ctx, player, dagger_entity_id) returns a
-- timed wield intent only after ownership, mutation, and shield checks.
function equipment.prepare_wield(ctx, actor, item_id)
    local current = equipment.in_slot(ctx, actor, "weapon")
    local entity = item_id ~= 0 and ctx:entity(item_id) or nil

    if entity == current then
        return { message = item_id == 0 and "You are already empty-handed." or
            "You are already wielding that." }
    end

    if item_id == 0 then
        return { intent = { kind = 11 }, cost = 3 }
    end

    if mutation_effects.sum(ctx, actor,
        mutation_capabilities.HANDHELD_USE_FORBIDDEN) > 0 then
        return { message = "You cannot wield weapons without grasping hands." }
    end

    local item = entity and ctx:get(entity, "core.item")
    local carrier = entity and ctx:get(entity, "core.carried_by")

    if not item or not carrier or carrier.holder ~= actor then
        return { message = "You are not carrying that item." }
    end

    local kind = items.kind(item)
    items.validate(item, kind)

    local weapon = staves.weapon(kind)

    if not weapon then
        return { message = "You cannot wield that item." }
    end

    if not equipment.weapon_supported(weapon.skill_id) then
        return { message = "That weapon's combat is unavailable in the Go port." }
    end

    if ctx:has(entity, "core.equipped") then
        return { message = "You are wearing that item." }
    end

    local shield = equipment.in_slot(ctx, actor, "shield")

    if shield then
        local player = ctx:get(actor, "core.player")

        if not player then
            error("player has no identity")
        end

        local species = catalog.get("species", player.species_id)

        if equipment.needs_second_hand(ctx, actor, kind, species) then
            return { message = "You cannot wield that with only one hand." }
        end
    end

    return { intent = { kind = 11, item_id = entity }, cost = 5 }
end

-- Return a player-facing fit reason, including horn/antenna cases and a
-- two-hand shield conflict, while can_wear remains a simple predicate.
function equipment.validate_fit(ctx, actor, kind)
    local player = ctx:get(actor, "core.player")

    if not player then
        error("player has no species")
    end

    local species = catalog.get("species", player.species_id)

    if kind.id == "ARM_BARDING" or kind.id == "ARM_CENTAUR_BARDING" then
        return "You can't wear that!"
    end

    if not equipment.can_wear(ctx, actor, species, kind) then
        if kind.id == "ARM_HELMET" and
            mutation_levels.effective(ctx, actor,
                mutations.MUT_HORNS) > 0 then
            return "You can't wear that with your horns!"
        end

        if kind.id == "ARM_HELMET" and
            mutation_levels.effective(ctx, actor,
                mutations.MUT_ANTENNAE) > 0 then
            return "You can't wear that with your antennae!"
        end

        return "That armour does not fit you."
    end

    if kind.slot == "shield" then
        local weapon_id = equipment.in_slot(ctx, actor, "weapon")

        if weapon_id then
            local weapon = ctx:get(weapon_id, "core.item")
            local weapon_kind = items.kind(weapon)

            if equipment.needs_second_hand(ctx, actor, weapon_kind, species) then
                return "You cannot use that shield with your weapon."
            end
        end
    end

    return nil
end

-- Prepare wear or removal as a persisted multi-turn delay. Swapping armour
-- starts by removing the old slot occupant; nothing equips during this check.
-- Example: equipment.prepare_armour(ctx, player, mail_id, false).
function equipment.prepare_armour(ctx, actor, item_id, taking_off)
    local entity = item_id ~= 0 and ctx:entity(item_id) or nil
    local item = entity and ctx:get(entity, "core.item")
    local carrier = entity and ctx:get(entity, "core.carried_by")

    if not item or not carrier or carrier.holder ~= actor then
        return { message = "You are not carrying that armour." }
    end

    local kind = items.kind(item)

    if kind.class ~= "OBJ_ARMOUR" or not kind.armour then
        return { message = "That is not armour." }
    end

    if not armour_slots[kind.slot] then
        return { message = "Wearing that armour is unavailable in the Go port." }
    end

    if taking_off then
        local equipped = ctx:get(entity, "core.equipped")

        if not equipped or equipped.slot ~= kind.slot then
            return { message = "You are not wearing that." }
        end

        return {
            cost = 10,
            intent = { kind = 6 },
            delay = {
                old_item_id = entity,
                slot = kind.slot,
                phase = "remove",
                remaining = 4,
            },
        }
    end

    if ctx:has(entity, "core.equipped") then
        return { message = "You are already wearing that." }
    end

    local fit_message = equipment.validate_fit(ctx, actor, kind)

    if fit_message then
        return { message = fit_message }
    end

    local old = equipment.in_slot(ctx, actor, kind.slot)

    return {
        cost = 10,
        intent = { kind = 6 },
        delay = {
            item_id = entity,
            old_item_id = old,
            slot = kind.slot,
            phase = old and "remove" or "wear",
            remaining = 4,
        },
    }
end

-- Name completion messages from current identification state, so a newly
-- identified item is reported consistently with the inventory screen.
local function finish_message(ctx, entity, format)
    local name = identification.name(ctx, ctx:player(), entity)

    return string.format(format, name)
end

-- The command bridge calls this after the initial wear or removal turn.
-- Save the delay on the actor so leaving and restoring the game preserves the
-- phase, then report what the player has started doing.
function equipment.start(ctx, actor, delay)
    ctx:add(actor, "core.equipment_delay", delay)

    if delay.phase == phases.RING_SWAP then
        return "You start putting on your ring."
    end

    if delay.slot == jewellery_slots.AMULET then
        if delay.phase == "remove" then
            return "You start removing your amulet."
        end

        return "You start putting on your amulet."
    end

    if delay.phase == "remove" then
        return "You start removing your armour."
    end

    return "You start putting on your armour."
end

-- Remove the saved delay without changing slots. A cancelled action should
-- never equip an item merely because the player spent its first turn.
function equipment.cancel(ctx, actor)
    local delay = ctx:get(actor, "core.equipment_delay")

    if not delay then
        return "You are not changing your equipment."
    end

    ctx:remove(actor, "core.equipment_delay")

    if delay.phase == phases.RING_SWAP then
        return "You stop putting on your ring."
    end

    if delay.slot == jewellery_slots.AMULET then
        if delay.phase == "remove" then
            return "You stop removing your amulet."
        end

        return "You stop putting on your amulet."
    end

    if delay.phase == "remove" then
        return "You stop removing your armour."
    end

    return "You stop putting on your armour."
end

-- Call after each ten-aut continuation. This mutates the persisted delay and
-- equipment relations only when a phase reaches its final turn.
-- Recheck ring ownership and slot availability at commit time, since a
-- delayed item may have changed before its final turn.
function equipment.advance(ctx, actor)
    local delay = ctx:get(actor, "core.equipment_delay")

    if not delay then
        error("player has no equipment delay")
    end

    if delay.phase == phases.RING_SWAP then
        local carrier = ctx:get(delay.item_id, "core.carried_by")
        local available = jewellery.slot_allowed(ctx, actor,
            jewellery_kinds.RING, delay.slot)

        if not carrier or carrier.holder ~= actor or not available or
            jewellery.in_slot(ctx, actor, delay.slot) then
            ctx:remove(actor, "core.equipment_delay")

            return { "You can no longer put on that ring." }
        end

        local effects = require("policy.inventory.jewellery_effects")
        local capabilities = require("constants.jewellery_capabilities")
        local magic_before = effects.sum(ctx, actor, capabilities.MAX_MP)

        ctx:add(delay.item_id, "core.equipped", { slot = delay.slot })
        attunement.on_equip(ctx, actor, delay.item_id)

        if effects.sum(ctx, actor, capabilities.MAX_MP) ~= magic_before then
            local resources = require("policy.character.resources")

            resources.refresh_mp(ctx, actor)
        end

        ctx:remove(actor, "core.equipment_delay")

        return {
            finish_message(ctx, delay.item_id, "You put on your %s."),
        }
    end

    local messages = {}

    if delay.phase == "remove" then
        messages[#messages + 1] = finish_message(
            ctx, delay.old_item_id, "You continue taking off your %s.")
    else
        messages[#messages + 1] = finish_message(
            ctx, delay.item_id, "You continue putting on your %s.")
    end

    delay.remaining = delay.remaining - 1

    if delay.remaining > 0 then
        ctx:set(actor, "core.equipment_delay", delay)

        return messages
    end

    if delay.phase == "remove" then
        ctx:remove(delay.old_item_id, "core.equipped")
        if delay.slot == jewellery_slots.AMULET then
            attunement.on_remove(ctx, delay.old_item_id)
            acrobat.equipment_changed(ctx, actor)
        end
        messages[#messages + 1] = finish_message(
            ctx, delay.old_item_id, "You finish taking off your %s.")

        if delay.item_id and ctx:id(delay.item_id) ~= 0 then
            delay.phase = "wear"
            delay.remaining = 5
            ctx:set(actor, "core.equipment_delay", delay)

            if delay.slot == jewellery_slots.AMULET then
                messages[#messages + 1] = "You start putting on your amulet."
            else
                messages[#messages + 1] = "You start putting on your armour."
            end
        else
            ctx:remove(actor, "core.equipment_delay")
        end
    else
        ctx:add(delay.item_id, "core.equipped", { slot = delay.slot })
        if delay.slot == jewellery_slots.AMULET then
            attunement.on_equip(ctx, actor, delay.item_id)
        end
        ctx:remove(actor, "core.equipment_delay")
        messages[#messages + 1] = finish_message(
            ctx, delay.item_id, "You finish putting on your %s.")
    end

    return messages
end

return equipment
