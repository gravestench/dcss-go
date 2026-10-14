local items = require("policy.inventory.items")
local catalog = require("policy.catalog")

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
}

local armour_slots = {
    body = true,
    shield = true,
    head = true,
    cloak = true,
    gloves = true,
    boots = true,
}

local function rank(id)
    local value = sizes[id]

    if not value then
        error("unknown source size " .. tostring(id))
    end

    return value
end

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

function equipment.needs_second_hand(kind, size)
    return rank(size) < rank(kind.weapon.min_1h_size_id)
end

-- A prepared result gives the command bridge a free message or an intent and
-- cost. Species definitions come from the committed source catalog.
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

    local item = entity and ctx:get(entity, "core.item")
    local carrier = entity and ctx:get(entity, "core.carried_by")

    if not item or not carrier or carrier.holder ~= actor then
        return { message = "You are not carrying that item." }
    end

    local kind = items.kind(item)
    items.validate(item, kind)

    if kind.class ~= "OBJ_WEAPONS" or not kind.weapon then
        return { message = "You cannot wield that item." }
    end

    if not supported_weapons[kind.weapon.skill_id] then
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

        if equipment.needs_second_hand(kind, species.size) then
            return { message = "You cannot wield that with only one hand." }
        end
    end

    return { intent = { kind = 11, item_id = entity }, cost = 5 }
end

function equipment.validate_fit(ctx, actor, kind)
    local player = ctx:get(actor, "core.player")

    if not player then
        error("player has no species")
    end

    local species = catalog.get("species", player.species_id)

    if kind.id == "ARM_BARDING" or kind.id == "ARM_CENTAUR_BARDING" then
        return "You can't wear that!"
    end

    if kind.id == "ARM_HELMET" then
        local mutations = type(species.mutations) == "table" and species.mutations or {}

        for _, mutation in ipairs(mutations) do
            if mutation.id == "MUT_HORNS" and mutation.level <= 1 and mutation.amount > 0 then
                return "You can't wear that with your horns!"
            end
        end
    end

    local size = rank(species.size)

    if size < rank(kind.armour.fit_min_id) or size > rank(kind.armour.fit_max_id) then
        return "That armour does not fit you."
    end

    if kind.slot == "shield" then
        local weapon_id = equipment.in_slot(ctx, actor, "weapon")

        if weapon_id then
            local weapon = ctx:get(weapon_id, "core.item")
            local weapon_kind = items.kind(weapon)

            if equipment.needs_second_hand(weapon_kind, species.size) then
                return "You cannot use that shield with your weapon."
            end
        end
    end

    return nil
end

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

local function finish_message(ctx, entity, format)
    return string.format(format, items.kind(ctx:get(entity, "core.item")).name)
end

-- The command bridge calls this after the initial wear or removal turn.
function equipment.start(ctx, actor, delay)
    ctx:add(actor, "core.equipment_delay", delay)

    if delay.phase == "remove" then
        return "You start removing your armour."
    end

    return "You start putting on your armour."
end

function equipment.cancel(ctx, actor)
    local delay = ctx:get(actor, "core.equipment_delay")

    if not delay then
        return "You are not changing your equipment."
    end

    ctx:remove(actor, "core.equipment_delay")

    if delay.phase == "remove" then
        return "You stop removing your armour."
    end

    return "You stop putting on your armour."
end

-- Call after each ten-aut continuation. This mutates the persisted delay and
-- equipment relations only when a phase reaches its final turn.
function equipment.advance(ctx, actor)
    local delay = ctx:get(actor, "core.equipment_delay")

    if not delay then
        error("player has no equipment delay")
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
        messages[#messages + 1] = finish_message(
            ctx, delay.old_item_id, "You finish taking off your %s.")

        if ctx:id(delay.item_id) ~= 0 then
            delay.phase = "wear"
            delay.remaining = 5
            ctx:set(actor, "core.equipment_delay", delay)
            messages[#messages + 1] = "You start putting on your armour."
        else
            ctx:remove(actor, "core.equipment_delay")
        end
    else
        ctx:add(delay.item_id, "core.equipped", { slot = delay.slot })
        ctx:remove(actor, "core.equipment_delay")
        messages[#messages + 1] = finish_message(
            ctx, delay.item_id, "You finish putting on your %s.")
    end

    return messages
end

return equipment
