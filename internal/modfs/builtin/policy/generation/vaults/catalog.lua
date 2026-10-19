-- Example: A later mod vault follows authored source ranks when eligible records are listed.
local categories = require("constants.catalog")
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")
local entity_specs = require("policy.generation.vaults.specs.validate")

local catalog = {}
local loaded = false
local paths_by_id = {}
local parsed_by_id = {}

local arrival_file_order = {
    ["large"] = 1,
    ["simple"] = 2,
    ["small"] = 3,
    ["twisted"] = 4,
}

local shop_file_order = {
    ["alphashops"] = 1,
    ["shops"] = 2,
}

-- Source file and line rankings preserve the pinned DES order across virtual mod paths.
local function source_position(family, source)
    if family == "shop" then
        local file, line = source:match(
            "# Source: crawl%-ref/source/dat/des/builder/" ..
            "([a-z]+)%.des:(%d+)")

        return shop_file_order[file] or 3, tonumber(line) or 0
    end

    local file, line = source:match(
        "# Source: crawl%-ref/source/dat/des/" .. family ..
        "/([a-z]+)%.des:(%d+)")

    return arrival_file_order[file] or 5, tonumber(line) or 0
end

-- Preserve source file and line order before assigning map IDs, including hooks inserted at source positions.
local function ordered_definitions()
    local definitions = {}
    local origins = {}

    for family_order, family in ipairs({ "arrival", "shop" }) do
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

            local file_order, line_order = source_position(family,
                mod.bundled(path) or source)

            definitions[#definitions + 1] = {
                definition = definition,
                path = path,
                family_order = family_order,
                file_order = file_order,
                line_order = line_order,
            }
        end
    end

    -- Compare family, source file, then line rank so virtual path discovery cannot reorder vaults.
    table.sort(definitions, function(left, right)
        if left.family_order ~= right.family_order then
            return left.family_order < right.family_order
        end

        if left.file_order ~= right.file_order then
            return left.file_order < right.file_order
        end

        if left.line_order ~= right.line_order then
            return left.line_order < right.line_order
        end

        return left.path < right.path
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
