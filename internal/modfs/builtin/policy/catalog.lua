-- Every content record is registered by its own discoverable Lua file.
local catalog = {}

-- Example: catalog.get("items", "POT_HEAL_WOUNDS") rejects removed records before item use.
-- Treat removed and enum-only records as unavailable to gameplay while still
-- retaining their stable IDs in registration data for source fidelity.
function catalog.get(category, id)
    local definition = register.get(category, id)

    if definition.status == "removed" or definition.status == "enum_only" then
        error("unknown active " .. category .. " ID " .. tostring(id))
    end

    return definition
end

-- Return definitions by stable ID order so equivalent catalogs drive the same seeded traversal.
function catalog.all(category)
    local definitions = {}

    -- IDs are sorted before traversal, so file load order and file names do
    -- not change a seeded choice from the same effective catalog.
    for _, id in ipairs(register.ids(category)) do
        definitions[#definitions + 1] = register.get(category, id)
    end

    return definitions
end

return catalog
