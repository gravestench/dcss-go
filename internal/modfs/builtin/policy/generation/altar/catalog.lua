-- The source overflow family is a complete, layered DES catalog. Its maps
-- belong to scheduled Dungeon god placement, so ordinary extra-vault draws
-- must not consume one before that schedule assigns its god identity.
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")

local catalog = {}
local definitions = {}
local ids = {}
local loaded = false

-- Parse each effective relative path once and reject duplicate NAMEs.
-- Sorting IDs keeps later weighted selection independent of file order.
function catalog.load()
    if loaded then
        return
    end

    for _, path in ipairs(mod.paths("vaults/altar", ".des")) do
        local definition = des.parse(path, mod.read(path))

        if definitions[definition.id] then
            error("duplicate overflow altar NAME " .. definition.id)
        end

        hooks.validate(definition)
        definitions[definition.id] = definition
        ids[#ids + 1] = definition.id
    end

    table.sort(ids)
    loaded = true
end

-- Return source ID order without imposing discovery order on game seeds.
function catalog.ids()
    catalog.load()

    return ids
end

-- An absent name is a caller error to handle, not an implicit fallback map.
function catalog.get(id)
    catalog.load()

    return definitions[id]
end

return catalog
