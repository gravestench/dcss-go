-- Theory of operation: a scheduled branch entrance can own an authored DES
-- map on its parent floor. Temple, Snake, and Slime choose from effective
-- source maps, then use the map's keyed entrance as the actual linked stair.
-- The ordinary vault fitter handles terrain, connectors, and saved records.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local families = require("constants.vault_families")
local tags = require("constants.vault_tags")
local extra = require("policy.generation.vaults.extra")
local temple = require("policy.generation.temple.catalog")
local vaults = require("policy.generation.vaults.catalog")

local entry = {}

-- Each entry family's DES tag, directory, and keyed terrain feature are
-- data. New Lair branches can join this table without another selector.
local source_entries = {
    [branches.BRANCH_SNAKE] = {
        family = families.SNAKE_ENTRY,
        tag = tags.SNAKE_ENTRY,
        feature = features.ENTER_SNAKE,
    },
    [branches.BRANCH_SLIME] = {
        family = families.SLIME_ENTRY,
        tag = tags.SLIME_ENTRY,
        feature = features.ENTER_SLIME,
    },
}

-- Temple keeps its dedicated catalog but follows the same placement and
-- retry contract as branch maps from the effective extra-vault catalog.
function entry.supports(branch_id)
    return branch_id == branches.BRANCH_TEMPLE or
        source_entries[branch_id] ~= nil
end

-- Temple has its own catalog because its entry files are not ordinary
-- extra vaults. Snake and Slime live in the normal effective DES catalog.
local function definitions(branch_id)
    local result = {}

    if branch_id == branches.BRANCH_TEMPLE then
        for _, id in ipairs(temple.entry_ids()) do
            result[#result + 1] = temple.entry(id)
        end
    elseif source_entries[branch_id] then
        local specification = source_entries[branch_id]

        vaults.load()

        for _, id in ipairs(register.ids(categories.VAULTS)) do
            local definition = register.get(categories.VAULTS, id)

            if definition.family == specification.family and
                definition.tags[specification.tag] then
                result[#result + 1] = vaults.get(id)
            end
        end
    else
        error("branch has no authored entrance family: " ..
            tostring(branch_id))
    end

    table.sort(result, function(left, right)
        return left.id < right.id
    end)

    return result
end

-- Expose the effective pool for mod and source-catalog tests. Source
-- weights are preserved; a disabled map contributes no candidate.
function entry.candidates(branch_id)
    local choices = {}

    for _, definition in ipairs(definitions(branch_id)) do
        if definition.weight > 0 then
            choices[#choices + 1] = {
                definition = definition,
                weight = definition.weight,
            }
        end
    end

    return choices
end

-- Remove a failed candidate after drawing it, so retries give each
-- remaining source map one weighted opportunity to fit this floor.
local function draw(builder, choices)
    local total = 0

    for _, candidate in ipairs(choices) do
        total = total + candidate.weight
    end

    local pick = builder:roll(total)

    for index, candidate in ipairs(choices) do
        pick = pick - candidate.weight

        if pick < 0 then
            table.remove(choices, index)

            return candidate.definition
        end
    end

    error("branch entry weighted draw exceeded its candidates")
end

-- Read the final KFEAT record after source substitutions and orientation.
-- A raw MAP glyph could have moved, so it cannot identify the live stair.
local function entrance_point(placed, feature)
    local found

    for _, record in ipairs(placed.records) do
        if record.kind == effects.FEATURE and
            record.directive == directives.KFEAT and
            record.identity == feature then
            if found then
                error("branch entry " .. placed.id ..
                    " has more than one entrance feature")
            end

            found = {
                x = record.x,
                y = record.y,
            }
        end
    end

    if not found then
        error("branch entry " .. placed.id ..
            " has no entrance feature")
    end

    return found
end

-- Fit the selected map through the ordinary DES path, preserving its
-- source identity and typed content in the parent level's vault history.
-- As in source Crawl, a lone branch stair remains the fallback when no
-- authored entry can fit around this floor's protected cells.
function entry.place(ctx, builder, protected, required, player, branch_id)
    local choices = entry.candidates(branch_id)
    local specification = source_entries[branch_id]
    local feature = specification and specification.feature or
        features.ENTER_TEMPLE
    while #choices > 0 do
        local definition = draw(builder, choices)
        local placed = extra.place(ctx, builder, definition, {
            protected = protected,
            required = required,
            player = player,
        })

        if placed then
            local point = entrance_point(placed, feature)

            builder:set(point.x, point.y, ">")
            protected[point.x .. ":" .. point.y] = true

            return placed, point
        end

    end

    return nil, nil
end

return entry
