-- Successful map IDs reconstruct DCSS name and tag uniqueness across floors.
local catalog = require("policy.generation.vaults.catalog")
local temple = require("policy.generation.temple.catalog")
local altar = require("policy.generation.altar.catalog")

local used = {}

-- A regular map name and uniq_* tags outlive the floor where the map was
-- placed. The committed catalog supplies tags, so saves need only store IDs.
local function remember_run(state, vault)
    if not vault.tags.allow_dup then
        state.run_names[vault.id] = true
    end

    for tag in pairs(vault.tags) do
        if tag:sub(1, 5) == "uniq_" then
            state.run_tags[tag] = true
        end
    end
end

-- luniq names and tags are reset at each floor boundary, including after
-- save and restore. A map can use allow_dup and still carry luniq.
local function remember_level(state, vault)
    if vault.tags.luniq then
        state.level_names[vault.id] = true
    end

    for tag in pairs(vault.tags) do
        if tag:sub(1, 6) == "luniq_" then
            state.level_tags[tag] = true
        end
    end
end

-- Temple primary, entry, and overflow maps use dedicated catalogs but
-- remain part of the same saved map history as ordinary extra vaults.
local function prior_definition(id)
    local okay, definition = pcall(catalog.get, id)

    if okay then
        return definition
    end

    definition = temple.main(id) or temple.entry(id) or altar.get(id)

    if not definition then
        error("unknown saved vault " .. tostring(id))
    end

    return definition
end

-- Build current-floor state from saved successful maps on earlier floors.
-- Reading the effective catalog also reports missing IDs before a new draw.
function used.new(prior_ids)
    local state = {
        run_names = {},
        run_tags = {},
        level_names = {},
        level_tags = {},
        placed = {},
    }

    state.allows = used.allows
    state.add = used.add
    state.add_map = used.add_map
    state.ids = used.ids

    for _, id in ipairs(prior_ids or {}) do
        remember_run(state, prior_definition(id))
    end

    return state
end

-- Check both source name scopes and any shared uniqueness tags before a
-- selector spends a weighted draw on an unavailable map.
function used.allows(state, vault)
    if state.run_names[vault.id] or state.level_names[vault.id] then
        return false
    end

    for tag in pairs(vault.tags) do
        if state.run_tags[tag] or state.level_tags[tag] then
            return false
        end
    end

    return true
end

-- Record only a successfully placed map. Failed fits never consume a name
-- or tag, and the ordered ID list is what the level saves for later floors.
function used.add(state, vault)
    remember_run(state, vault)
    remember_level(state, vault)
    state.placed[#state.placed + 1] = vault.id
end

-- SUBVAULT helpers are independently named source maps. Remember them
-- immediately after their parent so later draws respect their uniqueness
-- tags and save history can prove ownership of their items and monsters.
function used.add_map(state, vault, map)
    used.add(state, vault)

    for _, id in ipairs(map.vault_ids or {}) do
        used.add(state, catalog.get(id))
    end
end

-- Return a copy so callers cannot alter placement history after generation.
function used.ids(state)
    local ids = {}

    for index, id in ipairs(state.placed) do
        ids[index] = id
    end

    return ids
end

return used
