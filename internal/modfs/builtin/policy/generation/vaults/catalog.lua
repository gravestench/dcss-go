-- Example: Renaming a DES file does not move its ID in a weighted draw.
local categories = require("constants.catalog")
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")
local entity_specs = require("policy.generation.vaults.specs.validate")

local catalog = {}
local loaded = false
local paths_by_id = {}
local parsed_by_id = {}

-- Sort effective definitions by ID. Source comments document provenance but
-- cannot influence a seeded game when a mod renames or replaces a file.
local function ordered_definitions()
    local definitions = {}
    local origins = {}

    for _, family in ipairs({ "arrival", "shop" }) do
        for _, path in ipairs(mod.paths("vaults/" .. family, ".des")) do
            local source = mod.read(path)
            local definition = des.parse(path, source)
            hooks.validate(definition)

            for _, operation in ipairs(definition.operations) do
                entity_specs.operation(definition, operation)
            end

            local prior = origins[definition.id]

            -- Reject duplicate vault IDs while building the catalog instead of silently replacing a map.
            if prior then
                error(string.format("duplicate vault NAME %s in %s and %s",
                    definition.id, prior, path))
            end

            origins[definition.id] = path

            definitions[#definitions + 1] = {
                definition = definition,
                path = path,
            }
        end
    end

    -- Stable IDs make discovery order irrelevant to weighted selection.
    table.sort(definitions, function(left, right)
        return left.definition.id < right.definition.id
    end)

    return definitions
end

-- Parse and cache the complete vault set once; later lookups reuse its stable ID-to-path table.
function catalog.load()
    if loaded then
        return
    end

    for _, entry in ipairs(ordered_definitions()) do
        local definition = entry.definition
        local selection = {
            id = definition.id,
            family = definition.family,
            tags = definition.tags,
            orientation = definition.orientation,
            weight = definition.weight,
            depths = definition.depths,
            chances = definition.chances,
        }

        register.definition(categories.VAULTS, selection)
        paths_by_id[definition.id] = entry.path
    end

    require("ids.catalog").finalize()
    loaded = true
end

-- Lookups parse on demand but use the stable path chosen during catalog load.
function catalog.get(id)
    catalog.load()

    local path = paths_by_id[id]

    if not path then
        error("unknown vault " .. tostring(id))
    end

    local parsed = parsed_by_id[id]

    if not parsed then
        parsed = des.parse(path, mod.read(path))
        parsed_by_id[id] = parsed
    end

    return parsed
end

return catalog
