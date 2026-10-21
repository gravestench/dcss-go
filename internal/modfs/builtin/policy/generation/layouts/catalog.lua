-- Theory of operation: the effective DES files are the layout catalog.
-- Their depth, branch weight, and family tags choose a Lua carving hook;
-- the shared stair pass then makes the resulting floor traversable. Sorting
-- IDs before a draw makes file discovery order irrelevant to a game seed.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local depth_rules = require("policy.generation.vaults.depth")
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")
local authored = require("policy.generation.layouts.authored")
local stairs = require("policy.generation.layouts.stairs")
local weights = require("policy.generation.vaults.weight")

local catalog = {}
local definitions = {}
local loaded = false

-- Procedural hooks write glyphs after DES parsing, so keyed colour and tile
-- declarations cannot be bound to cells until the hook finishes. Keep each
-- matching source cell as typed level data for rendering and save/restore.
local function procedural_styles(definition, builder)
    local records = {}

    for _, operation in ipairs(definition.operations) do
        local kind

        if operation.kind == directives.COLOUR then
            kind = effects.COLOUR
        elseif operation.kind == directives.TILE or
            operation.kind == directives.FTILE or
            operation.kind == directives.RTILE then
            kind = effects.TILE
        end

        if kind then
            local targets, identity = operation.argument:match(
                "^%s*(%S+)%s*[=:]%s*(.-)%s*$")

            if not targets then
                error("layout " .. definition.id .. " has invalid style declaration")
            end

            for y = 0, builder.height - 1 do
                for x = 0, builder.width - 1 do
                    local source = builder:cell(x, y)

                    if targets:find(source, 1, true) then
                        records[#records + 1] = {
                            kind = kind,
                            directive = operation.kind,
                            identity = identity,
                            source = source,
                            x = x,
                            y = y,
                            vault_id = definition.id,
                            pending = true,
                        }
                    end
                end
            end
        end
    end

    return records
end

-- A procedural layout needs one builder hook. An authored MAP can use
-- several run hooks as source-position operations inside placement.
-- Source validators run before stairs alter the open-area measurement.
local function methods(definition)
    local run
    local validate
    local authored_map = #definition.rows > 0

    for _, operation in ipairs(definition.operations) do
        if operation.kind == directives.HOOK_RUN then
            if not authored_map then
                if run then
                    error("layout " .. definition.id .. " has multiple run hooks")
                end

                run = operation.argument
            end
        elseif operation.kind == directives.HOOK_VALIDATE then
            if validate then
                error("layout " .. definition.id .. " has multiple validators")
            end

            validate = operation.argument
        end
    end

    if not run and not authored_map then
        error("layout " .. definition.id ..
            " has neither an authored MAP nor a run hook")
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

        if weights.for_branch(definition, branches.BRANCH_DUNGEON) > 0 or
            #definition.places > 0 then
            hooks.validate(definition)
        end

        register.definition(categories.LAYOUTS, {
            id = definition.id,
            family = definition.family,
            tags = definition.tags,
            weight = definition.weight,
            weights = definition.weights,
            depths = definition.depths,
            places = definition.places,
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
local function candidates_for(branch_id, local_depth, branch_bottom,
    primary_tags)
    local candidates = {}
    local total = 0

    for _, id in ipairs(catalog.ids()) do
        local definition = catalog.get(id)
        local weight = weights.for_branch(definition, branch_id,
            local_depth, branch_bottom)

        if #definition.places == 0 and weight > 0 and
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

    return candidates, total
end

-- PLACE names a specific floor. Draw among matching authored layouts
-- before the ordinary DEPTH pool; explicit maps never leak into that pool.
local function placed_candidates(branch_id, local_depth, branch_bottom,
    primary_tags)
    local candidates = {}
    local total = 0

    for _, id in ipairs(catalog.ids()) do
        local definition = catalog.get(id)
        local weight = weights.for_branch(definition, branch_id,
            local_depth, branch_bottom)
        local place = {
            depths = definition.places,
        }

        if #definition.places > 0 and weight > 0 and
            depth_rules.eligible(place, branch_id,
                local_depth, branch_bottom) and
            catalog.compatible(definition, primary_tags) then
            total = total + weight
            candidates[#candidates + 1] = {
                definition = definition,
                weight = weight,
            }
        end
    end

    return candidates, total
end

-- A scheduled branch can keep its source-labelled entrance even when its
-- primary layout family has not yet been ported. Availability is derived
-- from the effective DES catalog, including overlays, not a branch switch.
function catalog.has_candidates(branch_id, local_depth)
    local branch = register.get(categories.BRANCHES, branch_id)
    local _, placed_total = placed_candidates(branch_id, local_depth,
        branch.depth)
    local _, ordinary_total = candidates_for(branch_id, local_depth,
        branch.depth)

    return placed_total > 0 or ordinary_total > 0
end

function catalog.choose(random, branch_id, local_depth, branch_bottom,
    primary_tags)
    local candidates, total = placed_candidates(branch_id, local_depth,
        branch_bottom, primary_tags)

    if total == 0 then
        candidates, total = candidates_for(branch_id, local_depth,
            branch_bottom, primary_tags)
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

-- Execute a procedural hook or place an authored MAP. A source validator
-- may reject a random shape; bounded retries consume new draws without
-- changing layout identity. The postpass adds missing connected stairs.
function catalog.execute(ctx, definition, branch_id, local_depth, profile,
    prior_vault_ids)
    local run, validate = methods(definition)
    local branch = register.get(categories.BRANCHES, branch_id)
    local api = {
        ctx = ctx,
        definition = definition,
        branch_id = branch_id,
        branch_bottom = branch.depth,
        branch = branch.abbreviation,
        depth = local_depth,
        absolute_depth = branch.absolute_depth + local_depth - 1,
        prior_vault_ids = prior_vault_ids,
    }

    -- Source layout validators can reject many draws before a connected
    -- floor has enough open area, especially with sparse room connectors.
    for _ = 1, 64 do
        local result

        if run then
            result = hooks.run(definition, run, api)
        else
            result = authored.execute(api)
        end

        if type(result) ~= "table" or not result.builder then
            error("layout " .. definition.id .. " did not return a builder")
        end

        if not validate or hooks.run(definition, validate, result) then
            result.stairs = stairs.complete(result.builder, profile)
            result.rows = result.builder:rows()
            result.id = definition.id

            if run then
                local styles = procedural_styles(definition, result.builder)

                result.records = result.records or {}

                for _, record in ipairs(styles) do
                    result.records[#result.records + 1] = record
                end
            end

            return result
        end
    end

    error("layout " .. definition.id .. " failed source validation after 64 attempts")
end

return catalog
