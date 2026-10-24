local catalog = require("policy.catalog")
local levels = require("policy.mutations.levels")

local registry = {}
local registered = {}
local by_mutation = {}

-- This registry maps mutation-granted abilities to their usability, preparation, and resolution hooks.
function registry.add(id, definition)
    if type(id) ~= "string" or id == "" or registered[id] then
        error("duplicate or invalid ability " .. tostring(id))
    end

    if type(definition) ~= "table" or
        (definition.mutation_id and
            type(definition.mutation_id) ~= "string") or
        type(definition.name) ~= "string" or
        type(definition.prepare) ~= "function" or
        type(definition.resolve) ~= "function" or
        (definition.available and type(definition.available) ~= "function") or
        (definition.owns_cancellation ~= nil and
            type(definition.owns_cancellation) ~= "boolean") or
        (definition.confusion_ok ~= nil and
            type(definition.confusion_ok) ~= "boolean") or
        (definition.confirmation_needed and
            type(definition.confirmation_needed) ~= "function") or
        (definition.confirmation_message and
            type(definition.confirmation_message) ~= "function") then
        error("ability " .. id .. " has an invalid definition")
    end

    if definition.mutation_id then
        catalog.get("mutations", definition.mutation_id)
        by_mutation[definition.mutation_id] = true
    end

    registered[id] = definition
end

-- Example: registry.get(abilities.HOP) obtains Hop's prepare and resolve handlers.
-- Look up the installed handler set by stable ability ID, letting the action
-- dispatcher call a mod override without an ability-specific branch.
function registry.get(id)
    return registered[id]
end

-- Let content validation ask whether a mutation has an ability without
-- exposing the registry's mutable definition table.
function registry.has_mutation(id)
    return by_mutation[id] == true
end

-- Apply min/max mutation-level bounds before any stateful availability hook;
-- a two-level ability cannot be offered at level one even if its hook allows.
function registry.usable(definition, level)
    return level > 0 and
        (not definition.min_level or level >= definition.min_level) and
        (not definition.max_level or level <= definition.max_level)
end

-- Combine the effective mutation level with live state such as cooldown or
-- current form, so the menu and action resolver share one ownership check.
function registry.usable_now(ctx, player, definition)
    local level = definition.mutation_id and
        levels.effective(ctx, player, definition.mutation_id) or 1

    return registry.usable(definition, level) and
        (not definition.available or definition.available(ctx, player))
end

-- Recheck ownership at resolution time: an intent prepared earlier must not
-- execute after a mutation or form change removed the ability.
function registry.resolve(ctx, player, intent, aut)
    local definition = registered[intent.ability_id]

    if not definition or not registry.usable_now(ctx, player, definition) then
        error("player intent has no owned ability " ..
            tostring(intent.ability_id))
    end

    return definition.resolve(ctx, player, intent, aut)
end

-- Sort by displayed name for the menu, then by stable ID when mods choose
-- the same label. Neither registration order nor table iteration breaks ties.
local function available_before(left, right)
    if left.name == right.name then
        return left.id < right.id
    end

    return left.name < right.name
end

-- Build menu entries from currently usable abilities and their live ranges;
-- evaluate hooks by sorted ID so file registration order cannot change
-- stateful hook timing, then sort displayed names with ID as a tie-breaker.
function registry.available(ctx, player)
    local result = {}
    local ids = {}

    for id in pairs(registered) do
        ids[#ids + 1] = id
    end

    table.sort(ids)

    for _, id in ipairs(ids) do
        local definition = registered[id]
        local level = definition.mutation_id and
            levels.effective(ctx, player, definition.mutation_id) or 1

        if registry.usable_now(ctx, player, definition) then
            result[#result + 1] = {
                id = id,
                name = definition.name,
                level = level,
                range = definition.range and
                    definition.range(level, ctx, player) or 0,
                confirmation_needed = definition.confirmation_needed and
                    definition.confirmation_needed(ctx, player) or false,
            }
        end
    end

    table.sort(result, available_before)

    return result
end

return registry
