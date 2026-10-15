local catalog = require("policy.catalog")
local levels = require("policy.mutations.levels")

local registry = {}
local registered = {}
local ordered = {}
local by_mutation = {}

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
    ordered[#ordered + 1] = id
end

function registry.get(id)
    return registered[id]
end

function registry.has_mutation(id)
    return by_mutation[id] == true
end

function registry.usable(definition, level)
    return level > 0 and
        (not definition.min_level or level >= definition.min_level) and
        (not definition.max_level or level <= definition.max_level)
end

function registry.usable_now(ctx, player, definition)
    local level = definition.mutation_id and
        levels.effective(ctx, player, definition.mutation_id) or 1

    return registry.usable(definition, level) and
        (not definition.available or definition.available(ctx, player))
end

function registry.resolve(ctx, player, intent, aut)
    local definition = registered[intent.ability_id]

    if not definition or not registry.usable_now(ctx, player, definition) then
        error("player intent has no owned ability " ..
            tostring(intent.ability_id))
    end

    return definition.resolve(ctx, player, intent, aut)
end

function registry.available(ctx, player)
    local result = {}

    for _, id in ipairs(ordered) do
        local definition = registered[id]
        local level = definition.mutation_id and
            levels.effective(ctx, player, definition.mutation_id) or 1

        if registry.usable_now(ctx, player, definition) then
            result[#result + 1] = {
                id = id,
                name = definition.name,
                level = level,
                range = definition.range and
                    definition.range(level) or 0,
                confirmation_needed = definition.confirmation_needed and
                    definition.confirmation_needed(ctx, player) or false,
            }
        end
    end

    table.sort(result, function(left, right)
        return left.name < right.name
    end)

    return result
end

return registry
