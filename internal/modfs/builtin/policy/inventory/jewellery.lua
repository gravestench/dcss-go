local classes = require("ids.object_classes")
local kinds = require("constants.jewellery_kind")
local slots = require("constants.jewellery_slots")
local species_ids = require("ids.species")
local mutation_ids = require("ids.mutations")
local mutation_levels = require("policy.mutations.levels")
local catalog = require("policy.catalog")
local identification = require("policy.items.identification")
local intent = require("constants.intent")
local phases = require("constants.equipment_phases")
local capabilities = require("constants.jewellery_capabilities")
local magnitudes = require("constants.jewellery_magnitudes")

local jewellery = {}
local known_capabilities = {}

for _, capability in pairs(capabilities) do
    known_capabilities[capability] = true
end

-- Validate the catalog record before treating it as wearable; item class
-- alone does not tell us whether it occupies a ring or amulet slot.
-- Example: jewellery.kind(ring_definition) == kinds.RING.
function jewellery.kind(definition)
    if definition.class ~= classes.OBJ_JEWELLERY then
        return nil
    end

    local record = definition.jewellery
    local kind = record and record.kind

    if kind ~= kinds.RING and kind ~= kinds.AMULET then
        error("jewellery " .. tostring(definition.id) ..
            " has no valid slot kind")
    end

    if record.pluses ~= nil and type(record.pluses) ~= "boolean" then
        error("jewellery " .. tostring(definition.id) ..
            " has invalid pluses metadata")
    end

    return kind
end

-- Check that every effect capability has an executable magnitude, including
-- item-plus effects only on jewellery that permits pluses.
function jewellery.effects(definition)
    jewellery.kind(definition)

    local record = definition.jewellery
    local effects = record.effects

    if type(effects) ~= "table" or next(effects) == nil then
        error("jewellery " .. tostring(definition.id) ..
            " has no effect capabilities")
    end

    for capability, magnitude in pairs(effects) do
        if not known_capabilities[capability] then
            error("jewellery " .. tostring(definition.id) ..
                " has unknown capability " .. tostring(capability))
        end

        local plus = magnitude == magnitudes.ITEM_PLUS
        local numeric = type(magnitude) == "number" and
            magnitude == magnitude and magnitude ~= math.huge and
            magnitude ~= -math.huge

        if (plus and not record.pluses) or (not plus and not numeric) then
            error("jewellery " .. tostring(definition.id) ..
                " has invalid magnitude for " .. capability)
        end
    end

    return effects
end

-- Source: species.cc. A missing hand removes the first ordinary
-- ring slot or the last Octopode tentacle slot.
-- Example: jewellery.ring_slots(ctx, octopode) returns the currently usable
-- tentacle slots after the missing-hand mutation is applied.
function jewellery.ring_slots(ctx, player)
    local identity = ctx:get(player, "core.player")
    local octopode = identity.species_id == species_ids.SP_OCTOPODE
    local available = octopode and slots.OCTO or {
        slots.LEFT,
        slots.RIGHT,
    }
    local missing = mutation_levels.effective(ctx, player,
        mutation_ids.MUT_MISSING_HAND) > 0
    local result = {}

    for index, slot in ipairs(available) do
        if not missing or (octopode and index ~= 8) or
            (not octopode and slot ~= slots.LEFT) then
            result[#result + 1] = slot
        end
    end

    return result
end

-- Ask the live slot list for rings, so species anatomy and mutations affect
-- command validation as well as the display.
function jewellery.slot_allowed(ctx, player, kind, slot)
    if kind == kinds.AMULET then
        return slot == slots.AMULET
    end

    if kind ~= kinds.RING then
        return false
    end

    for _, candidate in ipairs(jewellery.ring_slots(ctx, player)) do
        if slot == candidate then
            return true
        end
    end

    return false
end

-- Restrict slot lookup to this player's carried equipment and fail on
-- duplicates, since two rings in one slot would corrupt effect totals.
function jewellery.in_slot(ctx, player, slot)
    local found

    for _, entity in ipairs(ctx:query({ "core.carried_by", "core.equipped" })) do
        local carrier = ctx:get(entity, "core.carried_by")
        local equipped = ctx:get(entity, "core.equipped")

        if carrier.holder == player and equipped.slot == slot then
            if found then
                error("duplicate equipped jewellery slot " .. slot)
            end

            found = entity
        end
    end

    return found
end

-- Reuse combat equipment's worn-item scan with only the jewellery slots this
-- species can currently use; that keeps effect sums consistent with anatomy.
function jewellery.worn(ctx, player)
    local combat_equipment = require("policy.combat.equipment")
    local selected = { [slots.AMULET] = true }

    for _, slot in ipairs(jewellery.ring_slots(ctx, player)) do
        selected[slot] = true
    end

    return combat_equipment.worn(ctx, player, selected)
end

-- Resolve an item ID to an owned jewellery entity before any timed action is
-- prepared; stale selection IDs must produce a free message, not a mutation.
local function held(ctx, player, item_id)
    local entity = item_id ~= 0 and ctx:entity(item_id) or nil
    local item = entity and ctx:get(entity, "core.item")
    local carrier = entity and ctx:get(entity, "core.carried_by")

    if not item or not carrier or carrier.holder ~= player then
        return nil, nil, "You are not carrying that jewellery."
    end

    local definition = catalog.get("items", item.kind_id)

    if definition.class ~= classes.OBJ_JEWELLERY or
        definition.explicitly_removed then
        return nil, nil, "That is not wearable jewellery."
    end

    return entity, definition
end

-- When every usable ring slot is full, return a selection prompt instead of silently replacing the first ring.
-- Recheck transformed-form slot usability even for an explicit choice, since
-- the player's form may have changed while the prompt was open.
local function replacement(ctx, player, input, available)
    local forms = require("policy.magic.effects.forms.player")
    local chosen = input.target_id

    if chosen and chosen ~= "" then
        for _, slot in ipairs(available) do
            if chosen == slot and forms.slot_usable(ctx, player, slot) then
                return slot
            end
        end

        return nil, { message = "That ring slot is unavailable." }
    end

    local options = {}

    for _, slot in ipairs(available) do
        local current = forms.slot_usable(ctx, player, slot) and
            jewellery.in_slot(ctx, player, slot)

        if current then
            options[#options + 1] = {
                id = slot,
                label = identification.name(ctx, player, current),
            }
        end
    end

    if #options == 0 then
        return nil, { message = "You cannot wear rings in this form." }
    end

    return nil, {
        selection = {
            kind = "item",
            title = "Replace which ring?",
            options = options,
        },
    }
end

-- Example: an amulet swap schedules removal and wear phases; an empty ring slot can be filled directly.
-- The prepared result stores any multi-turn work as an equipment delay, so
-- save/restore can resume a swap rather than silently finishing it.
function jewellery.prepare_put_on(ctx, player, input)
    local forms = require("policy.magic.effects.forms.player")
    if input.cancelled then
        return { message = "Okay." }
    end

    local entity, definition, message = held(ctx, player, input.item_id or 0)

    if message then
        return { message = message }
    end

    if ctx:has(entity, "core.equipped") then
        return { message = "You are already wearing that." }
    end

    local kind = jewellery.kind(definition)

    if kind == kinds.AMULET then
        if not forms.slot_usable(ctx, player, slots.AMULET) then
            return { message = "You cannot wear that in this form." }
        end

        local old = jewellery.in_slot(ctx, player, slots.AMULET)

        return {
            cost = 10,
            intent = { kind = intent.WAIT },
            delay = {
                item_id = entity,
                old_item_id = old,
                slot = slots.AMULET,
                phase = old and phases.REMOVE or phases.WEAR,
                remaining = 4,
            },
        }
    end

    local available = jewellery.ring_slots(ctx, player)
    local chosen

    for _, slot in ipairs(available) do
        if forms.slot_usable(ctx, player, slot) and
            not jewellery.in_slot(ctx, player, slot) then
            chosen = slot
            break
        end
    end

    if not chosen then
        chosen, message = replacement(ctx, player, input, available)

        if message then
            return message
        end
    end

    local old = jewellery.in_slot(ctx, player, chosen)

    if old then
        return {
            cost = 5,
            intent = {
                kind = intent.JEWELLERY_OFF,
                item_id = old,
            },
            delay = {
                item_id = entity,
                old_item_id = old,
                slot = chosen,
                phase = phases.RING_SWAP,
                remaining = 1,
            },
        }
    end

    return {
        cost = 5,
        intent = {
            kind = intent.JEWELLERY_ON,
            item_id = entity,
            target_id = chosen,
        },
    }
end

-- Removing a ring is immediate after a short action; amulets use a persisted
-- delay. Both routes verify current ownership and form-dependent access.
-- Example: jewellery.prepare_remove(ctx, player, { item_id = ring_id }).
function jewellery.prepare_remove(ctx, player, input)
    local forms = require("policy.magic.effects.forms.player")
    local entity, definition, message = held(ctx, player, input.item_id or 0)

    if message then
        return { message = message }
    end

    local equipped = ctx:get(entity, "core.equipped")
    local kind = jewellery.kind(definition)

    if not equipped or
        not jewellery.slot_allowed(ctx, player, kind, equipped.slot) then
        return { message = "You are not wearing that." }
    end

    if not forms.slot_usable(ctx, player, equipped.slot) then
        return { message = "You cannot remove that in this form." }
    end

    if kind == kinds.AMULET then
        return {
            cost = 10,
            intent = { kind = intent.WAIT },
            delay = {
                old_item_id = entity,
                slot = slots.AMULET,
                phase = phases.REMOVE,
                remaining = 4,
            },
        }
    end

    return {
        cost = 5,
        intent = {
            kind = intent.JEWELLERY_OFF,
            item_id = entity,
        },
    }
end

return jewellery
