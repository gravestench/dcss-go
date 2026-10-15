-- Catalog declarations own the source IDs. Policies import these named
-- references so an ID is never retyped as a value in gameplay logic.
local catalog_ids = {}
local proxy_categories = {}

local function resolve_id(ids, id)
    local category = proxy_categories[ids]
    local value = register.reference(category, id)

    rawset(ids, id, value)

    return value
end

function catalog_ids.registered(category)
    local ids = {}

    proxy_categories[ids] = category
    setmetatable(ids, { __index = resolve_id })

    return ids
end

function catalog_ids.finalize()
    register.validate_references()

    for ids, category in pairs(proxy_categories) do
        for _, id in ipairs(register.ids(category)) do
            ids[id] = id
        end
    end
end

return catalog_ids
