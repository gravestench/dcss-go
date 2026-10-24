-- Theory of operation: each god describes one source weapon capstone,
-- while this owner holds the free selected-item prompt and its timed
-- commit. Item identity, current worship, and eligibility are rechecked
-- at resolution so a saved prompt cannot brand a different item.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local identification = require("policy.items.identification")
local blessed_item = require("policy.abilities.weapon_blessing.item")
local object_classes = require("ids.object_classes")
local registry = require("policy.abilities.registry")
local selection_kinds = require("constants.selection_kinds")
local skills = require("ids.skills")
local mutations = require("ids.mutations")
local mutation_levels = require("policy.mutations.levels")

local blessing = {}
local definitions = {}

-- Each god keeps its own lifetime capstone flag. The no-grasping mutation
-- blocks weapon manipulation even when rank and piety are sufficient.
local function available(ctx, player, spec)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local spent = worship and worship.one_time_abilities or {}

    return costs.available(ctx, player, spec.god_id, 6) and
        not spent[spec.god_id] and
        mutation_levels.effective(ctx, player,
            mutations.MUT_NO_GRASPING) == 0
end

-- Read the live item and its holder instead of trusting a menu label.
-- Divine holy and pain brands permit ranged weapons; distortion does not.
local function eligible(ctx, player, entity, spec)
    local item = entity and ctx:get(entity, component.ITEM)
    local carrier = entity and ctx:get(entity, component.CARRIED_BY)

    if not item or not carrier or carrier.holder ~= player or
        ctx:has(entity, component.ITEM_ARTEFACT) then
        return false
    end

    local kind = catalog.get(categories.ITEMS, item.kind_id)

    return kind.class == object_classes.OBJ_WEAPONS and
        kind.weapon ~= nil and
        (spec.allow_ranged or
            kind.weapon.skill_id ~= skills.SK_RANGED_WEAPONS)
end

-- Build a deterministic menu of real Akara item IDs. The registry does
-- not depend on discovery order, and mods may change displayed names.
local function item_prompt(ctx, player, spec, handler)
    local options = {}

    for _, entity in ipairs(ctx:query({ component.ITEM })) do
        if handler.eligible(ctx, player, entity) then
            options[#options + 1] = {
                id = tostring(ctx:id(entity)),
                label = identification.name(ctx, player, entity),
            }
        end
    end

    if #options == 0 then
        return { message = spec.no_weapon_message }
    end

    return {
        selection = {
            kind = selection_kinds.ITEM,
            title = "Brand which weapon?",
            options = options,
        },
    }
end

-- One component carries only one prompt. Esc clears it even if worship
-- has changed since selection, allowing the player to recover the slot.
local function prepare(ctx, player, input, spec, handler)
    local pending = ctx:get(player, component.WEAPON_BLESS_CHOICE)

    if input.cancelled then
        if pending then
            ctx:remove(player, component.WEAPON_BLESS_CHOICE)
        end

        return "Okay."
    end

    if pending then
        if pending.ability_id ~= spec.ability_id or
            pending.god_id ~= spec.god_id or
            not handler.available(ctx, player) or
            not handler.eligible(ctx, player, pending.item) then
            ctx:remove(player, component.WEAPON_BLESS_CHOICE)

            return "That weapon is no longer available."
        end

        if not input.forced then
            return {
                confirmation = spec.confirmation(ctx, player,
                    pending.item),
            }
        end

        input.item_id = ctx:id(pending.item)

        return nil
    end

    local selected_id = tonumber(input.target_id)
    local selected = selected_id and ctx:entity(selected_id)

    if not selected then
        return item_prompt(ctx, player, spec, handler)
    end

    if not handler.eligible(ctx, player, selected) then
        return spec.invalid_weapon_message
    end

    ctx:add(player, component.WEAPON_BLESS_CHOICE, {
        item = selected,
        ability_id = spec.ability_id,
        god_id = spec.god_id,
    })

    return {
        confirmation = spec.confirmation(ctx, player, selected),
    }
end

-- Commit the brand and two source enchant attempts once. God-specific
-- conversion and area effects are attached at this same commitment point.
local function resolve(ctx, player, intent, spec, handler)
    local pending = ctx:get(player, component.WEAPON_BLESS_CHOICE)

    if not pending or
        pending.ability_id ~= spec.ability_id or
        pending.god_id ~= spec.god_id or
        not intent.item_id or
        ctx:id(pending.item) ~= ctx:id(intent.item_id) or
        not handler.available(ctx, player) or
        not handler.eligible(ctx, player, pending.item) then
        error("invalid divine weapon blessing intent")
    end

    blessed_item.apply(ctx, pending.item, spec)
    ctx:remove(player, component.WEAPON_BLESS_CHOICE)

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.one_time_abilities[spec.god_id] = true
    ctx:set(player, component.RELIGION_WORSHIP, worship)
    ctx:emit("religion", spec.success_message)

    if spec.after then
        spec.after(ctx, player, pending.item)
    end
end

-- Save validation consumes the same registered definition that prepares
-- the command; it cannot drift into a second hardcoded eligibility table.
function blessing.validate(ctx, player)
    local pending = ctx:get(player, component.WEAPON_BLESS_CHOICE)

    if not pending then
        return
    end

    local handler = definitions[pending.ability_id]

    if not handler or handler.god_id ~= pending.god_id or
        not handler.available(ctx, player) or
        not handler.eligible(ctx, player, pending.item) then
        error("invalid saved weapon blessing choice")
    end
end

-- A god module contributes one small definition and receives ordinary
-- ability methods. This is the shared source action, not a Go adapter.
function blessing.define(spec)
    if definitions[spec.ability_id] then
        error("duplicate weapon blessing " .. spec.ability_id)
    end

    local handler = {
        god_id = spec.god_id,
    }

    function handler.available(ctx, player)
        return available(ctx, player, spec)
    end

    function handler.eligible(ctx, player, entity)
        return eligible(ctx, player, entity, spec)
    end

    function handler.prepare(ctx, player, input)
        return prepare(ctx, player, input, spec, handler)
    end

    function handler.resolve(ctx, player, intent)
        return resolve(ctx, player, intent, spec, handler)
    end

    function handler.validate(ctx, player)
        return blessing.validate(ctx, player)
    end

    definitions[spec.ability_id] = handler
    registry.add(spec.ability_id, {
        name = spec.name,
        available = handler.available,
        owns_cancellation = true,
        prepare = handler.prepare,
        resolve = handler.resolve,
    })

    return handler
end

return blessing
