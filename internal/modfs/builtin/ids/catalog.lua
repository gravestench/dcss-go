-- Catalog ID proxies resolve references after layered content registration finishes.

-- Catalog declarations own the source IDs. Policies import these named
-- references so an ID is never retyped as a value in gameplay logic.
local catalog_ids = {}
local proxy_categories = {}

-- Resolve a missing field only after all layers have registered their IDs.
-- The reference check catches typos even when a policy imports an ID before
-- the matching content file has been loaded; caching avoids repeated checks.
local function resolve_id(ids, id)
    local category = proxy_categories[ids]
    local value = register.reference(category, id)

    rawset(ids, id, value)

    return value
end

-- Give a policy a category-specific ID table without copying literal IDs.
-- The metatable defers validation until registration has populated the catalog.
function catalog_ids.registered(category)
    local ids = {}

    proxy_categories[ids] = category
    setmetatable(ids, { __index = resolve_id })

    return ids
end

-- Seal the references after content loading. Filling each proxy from sorted
-- catalog IDs makes later iteration independent of Lua table or file order.
function catalog_ids.finalize()
    register.validate_references()

    for ids, category in pairs(proxy_categories) do
        for _, id in ipairs(register.ids(category)) do
            ids[id] = id
        end
    end
end

return catalog_ids
