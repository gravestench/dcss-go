local categories = require("constants.catalog")
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")

local catalog = {}
local loaded = false
local paths_by_id = {}
local parsed_by_id = {}

local source_file_order = {
    ["large"] = 1,
    ["simple"] = 2,
    ["small"] = 3,
    ["twisted"] = 4,
}

local function source_position(source)
    local file, line = source:match("# Source: crawl%-ref/source/dat/des/arrival/([a-z]+)%.des:(%d+)")

    return source_file_order[file] or 5, tonumber(line) or 0
end

local function ordered_definitions()
    local definitions = {}
    local origins = {}

    for _, path in ipairs(mod.paths("vaults/arrival", ".des")) do
        local source = mod.read(path)
        local definition = des.parse(path, source)
        hooks.validate(definition)
        local prior = origins[definition.id]

        if prior then
            error(string.format("duplicate vault NAME %s in %s and %s", definition.id, prior, path))
        end

        origins[definition.id] = path

        local file_order, line_order = source_position(mod.bundled(path) or source)

        definitions[#definitions + 1] = {
            definition = definition,
            path = path,
            file_order = file_order,
            line_order = line_order,
        }
    end

    table.sort(definitions, function(left, right)
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

function catalog.load()
    if loaded then
        return
    end

    for _, entry in ipairs(ordered_definitions()) do
        local definition = entry.definition
        local selection = {
            id = definition.id,
            tags = definition.tags,
            orientation = definition.orientation,
            weight = definition.weight,
        }

        register.definition(categories.VAULTS, selection)
        paths_by_id[definition.id] = entry.path
    end

    require("ids.catalog").finalize()
    loaded = true
end

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
