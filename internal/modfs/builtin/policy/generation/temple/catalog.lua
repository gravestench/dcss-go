-- Temple selection reads committed, layered DES definitions. Main maps and
-- Dungeon entries have different jobs, so one catalog validates each family
-- without treating either as an ordinary Dungeon layout.
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")
local directives = require("constants.vault_directives")

local catalog = {}
local mains = {}
local entries = {}
local main_ids = {}
local entry_ids = {}
local loaded = false

-- Parse each effective file once. Stable IDs make selection independent of
-- the filesystem's discovery order; duplicate NAMEs are always an error.
local function load_family(directory, destination, ids)
    for _, path in ipairs(mod.paths(directory, ".des")) do
        local definition = des.parse(path, mod.read(path))

        if destination[definition.id] then
            error("duplicate Temple NAME " .. definition.id)
        end

        hooks.validate(definition)
        destination[definition.id] = definition
        ids[#ids + 1] = definition.id
    end

    table.sort(ids)
end

-- Boot validation includes rarely selected maps so bad mod content fails
-- before the player reaches the Temple entrance.
function catalog.load()
    if loaded then
        return
    end

    load_family("vaults/temple", mains, main_ids)
    load_family("vaults/temple_entry", entries, entry_ids)
    loaded = true
end

-- Expose sorted main IDs without copying map metadata into another table.
function catalog.main_ids()
    catalog.load()

    return main_ids
end

-- Count source maps with no Lua hook. This remains 43 after the scripted
-- maps join the catalog, so it guards the independently authored MAP pool.
function catalog.static_count()
    catalog.load()

    local count = 0

    for _, id in ipairs(main_ids) do
        local scripted = false

        for _, operation in ipairs(mains[id].operations) do
            if operation.kind == directives.HOOK_RUN then
                scripted = true
                break
            end
        end

        if not scripted then
            count = count + 1
        end
    end

    return count
end

-- Expose sorted Dungeon entry IDs for source-weighted selection.
function catalog.entry_ids()
    catalog.load()

    return entry_ids
end

-- Return one parsed main map, preserving its authored operations and rows.
function catalog.main(id)
    catalog.load()

    return mains[id]
end

-- Return one parsed entry map, including its original O feature mapping.
function catalog.entry(id)
    catalog.load()

    return entries[id]
end

return catalog
