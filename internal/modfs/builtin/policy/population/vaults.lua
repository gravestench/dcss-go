local catalog = require("policy.catalog")
local factory = require("policy.population.factory")
local items = require("policy.inventory.items")
local effects = require("constants.vault_effects")

local vaults = {}

local function names_by_id(category, allowed)
    local names = {}

    for _, definition in ipairs(catalog.all(category)) do
        if (not allowed or allowed[definition.id]) and
            definition.name and definition.name ~= "" and
            definition.status ~= "removed" and
            definition.status ~= "enum_only" and
            not definition.explicitly_removed then
            names[definition.name] = names[definition.name] or definition.id
        end
    end

    return names
end

local function place_item(ctx, kind_id, level, record)
    if not ctx:walkable(level.id, record.x, record.y) then
        return false
    end

    local definition = catalog.get("items", kind_id)
    local item = {
        kind_id = kind_id,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    }

    local valid = pcall(items.validate, item, definition)

    if not valid then
        return false
    end

    local entity = ctx:create()

    ctx:add(entity, "core.item", item)
    ctx:add(entity, "core.position", {
        level_id = level.id,
        x = record.x,
        y = record.y,
    })

    return true
end

local function place_monster(ctx, kind_id, level, record)
    if not ctx:walkable(level.id, record.x, record.y) or
        ctx:actor_at(level.id, record.x, record.y) then
        return false
    end

    factory.spawn(ctx, kind_id, level.id, record.x, record.y)

    return true
end

function vaults.materialize(ctx, level, allowed)
    if not level.vault_records or #level.vault_records == 0 then
        return 0, {}
    end

    local monsters = names_by_id("monsters", allowed)
    local item_names = names_by_id("items")
    local materialized = {}
    local actors = 0

    for _, record in ipairs(level.vault_records or {}) do
        local kind_id
        local placed = false

        if record.kind == effects.MONSTER then
            kind_id = monsters[record.identity]

            if kind_id then
                placed = place_monster(ctx, kind_id, level, record)

                if placed then
                    actors = actors + 1
                end
            end
        elseif record.kind == effects.ITEM then
            kind_id = item_names[record.identity]

            if kind_id then
                placed = place_item(ctx, kind_id, level, record)
            end
        end

        if placed then
            materialized[#materialized + 1] = {
                level_id = level.id,
                index = record.index,
            }
        end
    end

    return actors, materialized
end

return vaults
