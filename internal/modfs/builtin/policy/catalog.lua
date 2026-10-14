-- Source-traced catalogs are committed Lua modules. Load only the catalog a
-- rule needs, then index it once so gameplay never scans records by ID.

local collections = {
    branches = { module = "data.branches", field = "branches" },
    items = { module = "data.items", field = "items" },
    monsters = { module = "data.monsters", field = "monsters" },
    spells = { module = "data.spells", field = "spells" },
}

local indexes = {}
local catalog = {}

function catalog.get(category, id)
    if category == "species" or category == "jobs" then
        return register.get(category, id)
    end

    local collection = collections[category]

    if not collection then
        error("unknown catalog " .. tostring(category))
    end

    local index = indexes[category]

    if not index then
        index = {}
        local artifact = require(collection.module)

        for _, definition in ipairs(artifact[collection.field]) do
            if index[definition.id] then
                error("duplicate " .. category .. " ID " .. definition.id)
            end

            index[definition.id] = definition
        end

        indexes[category] = index
    end

    local definition = index[id]

    if not definition or definition.status == "removed" or
        definition.status == "enum_only" then
        error("unknown active " .. category .. " ID " .. tostring(id))
    end

    return definition
end

return catalog
