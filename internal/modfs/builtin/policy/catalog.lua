-- Every content record is registered by its own discoverable Lua file.
local catalog = {}

function catalog.get(category, id)
    local definition = register.get(category, id)

    if definition.status == "removed" or definition.status == "enum_only" then
        error("unknown active " .. category .. " ID " .. tostring(id))
    end

    return definition
end

function catalog.all(category)
    local definitions = {}

    -- Registration order preserves the source catalog's selection order.
    for _, id in ipairs(register.ordered_ids(category)) do
        definitions[#definitions + 1] = register.get(category, id)
    end

    return definitions
end

return catalog
