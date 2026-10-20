-- Theory of operation: the effective DES files are the layout catalog.
-- Their depth, branch weight, and family tags choose a Lua carving hook;
-- the shared stair pass then makes the resulting floor traversable. Sorting
-- IDs before a draw makes file discovery order irrelevant to a game seed.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local depth_rules = require("policy.generation.vaults.depth")
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")
local stairs = require("policy.generation.layouts.stairs")
local weights = require("policy.generation.vaults.weight")

local catalog = {}
local definitions = {}
local loaded = false

-- A layout needs exactly one run hook. The source may add a size validator,
-- which is checked before stairs alter the map's open-area measurement.
local function methods(definition)
    local run
    local validate

    for _, operation in ipairs(definition.operations) do
        if operation.kind == directives.HOOK_RUN then
            if run then
                error("layout " .. definition.id .. " has multiple run hooks")
            end

            run = operation.argument
        elseif operation.kind == directives.HOOK_VALIDATE then
            if validate then
                error("layout " .. definition.id .. " has multiple validators")
            end

            validate = operation.argument
        end
    end

    if not run then
        error("layout " .. definition.id .. " has no run hook")
    end

    return run, validate
end

-- Register every effective source map, including zero-weight Dungeon maps.
-- Positive Dungeon candidates must have working Lua hooks at startup; a
-- disabled map can remain as metadata until its branch is implemented.
function catalog.load()
    if loaded then
        return
    end

    for _, path in ipairs(mod.paths("vaults/layout", ".des")) do
        local definition = des.parse(path, mod.read(path))
        local prior = definitions[definition.id]

        if definition.family ~= "layout" or not definition.tags.layout then
            error(path .. ": layout definition needs the layout tag")
        end

        if prior then
            error(string.format("duplicate layout NAME %s in %s and %s",
                definition.id, prior.path, path))
        end

        methods(definition)

        if weights.for_branch(definition, branches.BRANCH_DUNGEON) > 0 then
            hooks.validate(definition)
        end

        register.definition(categories.LAYOUTS, {
            id = definition.id,
            family = definition.family,
            tags = definition.tags,
            weight = definition.weight,
            weights = definition.weights,
            depths = definition.depths,
        })

        definitions[definition.id] = definition
    end

    loaded = true
end

-- Registry IDs are sorted, so adding unrelated files never reorders a
-- weighted draw among the definitions already present.
function catalog.ids()
    catalog.load()

    return register.ids(categories.LAYOUTS)
end

-- Return the parsed DES map, including its source hook operations.
function catalog.get(id)
    catalog.load()

    local definition = definitions[id]

    if not definition then
        error("unknown layout " .. tostring(id))
    end

    return definition
end

-- An arrival's layout_* tags whitelist family types; nolayout_* tags veto
-- them. A normal arrival with neither accepts any ordinary layout family.
function catalog.compatible(definition, primary_tags)
    local family

    for tag in pairs(definition.tags) do
        family = tag:match("^layout_type_(.+)$") or family
    end

    if not family then
        error("layout " .. definition.id .. " has no layout_type tag")
    end

    local restricted = false

    for tag in pairs(primary_tags or {}) do
        if tag:match("^layout_(.+)$") then
            restricted = true
        end
    end

    return not (primary_tags and definition.tags.no_primary_vault) and
        not (primary_tags and primary_tags["nolayout_" .. family]) and
        (not restricted or primary_tags["layout_" .. family] == true)
end

-- Filter against effective branch and depth metadata before making one
-- weighted draw. No fallback is allowed when a mod removes all candidates.
function catalog.choose(random, branch_id, local_depth, branch_bottom,
    primary_tags)
    local candidates = {}
    local total = 0

    for _, id in ipairs(catalog.ids()) do
        local definition = catalog.get(id)
        local weight = weights.for_branch(definition, branch_id,
            local_depth, branch_bottom)

        if weight > 0 and
            depth_rules.eligible(definition, branch_id,
                local_depth, branch_bottom) and
            catalog.compatible(definition, primary_tags) then
            total = total + weight
            candidates[#candidates + 1] = {
                definition = definition,
                weight = weight,
            }
        end
    end

    if total == 0 then
        error("no weighted layout for this branch, depth, and primary map")
    end

    local draw = random:roll(total)

    for _, candidate in ipairs(candidates) do
        if draw < candidate.weight then
            return candidate.definition
        end

        draw = draw - candidate.weight
    end

    error("layout weight selection exceeded the catalog")
end

-- Execute only the method named by DES. A source validator may reject a
-- random shape; bounded retries consume new draws without changing layout
-- identity. The shared postpass then adds the missing connected stairs.
function catalog.execute(ctx, definition, branch_id, local_depth)
    local run, validate = methods(definition)
    local branch = register.get(categories.BRANCHES, branch_id)
    local api = {
        ctx = ctx,
        branch = branch.abbreviation,
        depth = local_depth,
        absolute_depth = local_depth,
    }

    for _ = 1, 8 do
        local result = hooks.run(definition, run, api)

        if type(result) ~= "table" or not result.builder then
            error("layout " .. definition.id .. " did not return a builder")
        end

        if not validate or hooks.run(definition, validate, result) then
            result.stairs = stairs.complete(result.builder)
            result.rows = result.builder:rows()
            result.id = definition.id

            return result
        end
    end

    error("layout " .. definition.id .. " failed source validation after 8 attempts")
end

return catalog
