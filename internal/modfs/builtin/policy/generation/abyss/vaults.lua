-- Theory of operation: procedural Abyss terrain is already typed when
-- the DES fitter runs. Build a temporary DES glyph view for source hooks,
-- place an authored map through the shared fitter, then project only its
-- occupied cells back onto the typed sample. The source records remain
-- available for items, monsters, markers, and later Abyss shifts.
local abyss = require("constants.abyss")
local branches = require("ids.branches")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local placement = require("policy.generation.vaults.placement")
local regular = require("policy.generation.vaults.regular")
local terrain = require("constants.terrain")
local effects = require("constants.vault_effects")
local used = require("policy.generation.vaults.used")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local vault_catalog = require("policy.generation.vaults.catalog")
local eligibility = require("policy.generation.vaults.eligibility")
local weights = require("policy.generation.vaults.weight")

local vaults = {}

-- The branch catalog supplies depth and absolute depth for both ordinary
-- furniture and later tagged maps. One construction path avoids a tagged
-- rune accidentally using a different depth from the surrounding window.
local function selection_context(state)
    local branch = catalog.get(categories.BRANCHES,
        branches.BRANCH_ABYSS)
    local player = {
        branch_id = branches.BRANCH_ABYSS,
        depth = state.branch_depth,
        branch_bottom = branch.depth,
        absolute_depth = branch.absolute_depth + state.branch_depth,
        started = true,
        prior_vault_ids = state.selected_map_ids or {},
    }
    local context = {
        branch_id = branches.BRANCH_ABYSS,
        depth = state.branch_depth,
        branch_bottom = branch.depth,
        absolute_depth = player.absolute_depth,
        branch_vault_family = abyss.VAULT_FAMILY,
        player = player,
        used = used.new(state.selected_map_ids),
    }

    return player, context
end

-- Choose one deterministic source glyph for each typed feature that the
-- procedural sampler can draw. A borrowed feature without a DES glyph
-- appears as open background to the fitter but remains typed outside the
-- chosen map's occupied cells.
local source_glyph = {
    [terrain.DNGN_FLOOR] = ".",
    [terrain.DNGN_ROCK_WALL] = "x",
    [terrain.DNGN_STONE_WALL] = "c",
    [terrain.DNGN_METAL_WALL] = "v",
    [terrain.DNGN_CRYSTAL_WALL] = "b",
    [terrain.DNGN_TREE] = "t",
    [terrain.DNGN_SHALLOW_WATER] = "W",
    [terrain.DNGN_DEEP_WATER] = "w",
    [terrain.DNGN_LAVA] = "l",
    [terrain.DNGN_CLOSED_DOOR] = "+",
    [terrain.DNGN_CLOSED_CLEAR_DOOR] = "~",
    [terrain.DNGN_STONE_ARCH] = "A",
}

-- Do not hand a DES hook the live sample rows: map transforms and vetoes
-- may edit their temporary builder while trying a candidate location.
local function builder_from(ctx, cells)
    local builder = grid.new(ctx, abyss.WIDTH, abyss.HEIGHT)

    for y, row in ipairs(cells) do
        for x, feature in ipairs(row) do
            builder:set(x - 1, y - 1,
                source_glyph[feature] or ".")
        end
    end

    return builder
end

-- A placed record may still be pending, even if its source glyph painted
-- terrain now. Clone the sampled matrix before applying that record's
-- existing terrain policy, so a veto cannot alter the caller's plan.
local function project(cells, builder, placed, ctx)
    local projected = {}

    for y, row in ipairs(cells) do
        projected[y] = {}

        for x, feature in ipairs(row) do
            projected[y][x] = feature
        end
    end

    for _, point in ipairs(placed.occupied) do
        local glyph = builder:cell(point.x, point.y)
        local feature = features.from_source_glyph[glyph]

        if not feature then
            error("Abyss DES map produced an unknown terrain glyph " ..
                tostring(glyph))
        end

        projected[point.y + 1][point.x + 1] = feature
    end

    local records = features.apply_vault_terrain(
        projected, placed.records, ctx, abyss.LEVEL_ID)

    return projected, records
end

-- Place exactly one requested source definition. Weighted selection and
-- the source's six-vault stop rule are a separate stage over this method.
function vaults.place_one(ctx, cells, definition, player, options)
    if definition.tags.dummy then
        error("an Abyss dummy is a null weighted choice, not a map")
    end

    local builder = builder_from(ctx, cells)
    local placed = placement.place(ctx, builder,
        definition, player, options)
    local projected, records = project(cells, builder, placed, ctx)

    -- Most DES floor glyphs have no effect record. Record their ownership
    -- anyway: the moving-window mask must preserve the whole painted map,
    -- not merely its walls, items, and monsters near the player.
    local recorded = {}

    for _, record in ipairs(records) do
        recorded[record.x .. ":" .. record.y] = true
    end

    for _, point in ipairs(placed.occupied) do
        local key = point.x .. ":" .. point.y

        if not recorded[key] then
            records[#records + 1] = {
                kind = effects.SOURCE_FEATURE,
                vault_id = placed.id,
                identity = projected[point.y + 1][point.x + 1],
                source = builder:cell(point.x, point.y),
                x = point.x,
                y = point.y,
                pending = false,
                arguments = {},
            }
        end
    end

    return {
        id = placed.id,
        tags = placed.tags,
        cells = projected,
        records = records,
        occupied = placed.occupied,
        bounds = placed.bounds,
        vault_ids = placed.vault_ids,
    }
end

-- Geometry conflicts are ordinary misses in the source's bounded vault
-- search. A malformed hook or unknown terrain remains an immediate error
-- so a broken mod does not quietly vanish from the generated floor.
local function fit_conflict(message)
    return message:find("conflicts with", 1, true) or
        message:find("cannot fit", 1, true) or
        message:find("validation rejected placement", 1, true) or
        message:find("MAP does not fit", 1, true)
end

-- The source tries ordinary depth maps until its first successful map,
-- then asks for `extra` maps. A weighted dummy is a deliberate empty
-- choice. Keep the six-map cap and the increasing early-stop chance.
function vaults.fill(ctx, cells, state, initial_protected)
    local selector = grid.new(ctx, abyss.WIDTH, abyss.HEIGHT)
    local player, context = selection_context(state)
    local protected = {}
    local records = {}
    local ids = {}
    local placed = {}
    local count = 0

    context.excluded_tags = {
        "abyss_rune",
        "abyss_exit",
    }

    for key, value in pairs(initial_protected or {}) do
        protected[key] = value
    end

    -- The shared depth selector accepts a fitter callback. Keep the
    -- sampled cells local to this call, committing them only on success.
    local function fit(fit_ctx, _, definition)
        local okay, result = pcall(vaults.place_one,
            fit_ctx, cells, definition, player, {
                protected = protected,
            })

        if not okay then
            if fit_conflict(tostring(result)) then
                return nil
            end

            error(result)
        end

        cells = result.cells

        for _, point in ipairs(result.occupied) do
            protected[point.x .. ":" .. point.y] = true
        end

        for _, record in ipairs(result.records) do
            records[#records + 1] = record
        end

        for _, id in ipairs(result.vault_ids or {}) do
            ids[#ids + 1] = id
        end

        return result
    end

    -- Extra maps do not advance the normal-vault count, but attempts are
    -- bounded just as the source bounds rejected placement retries.
    for _ = 1, 100 do
        context.regular_extra_only = count > 0

        local id = regular.place(ctx, selector, context,
            placed, fit)

        if not id then
            break
        end

        ids[#ids + 1] = id

        if not placed[#placed].tags.extra then
            count = count + 1

            if count >= 6 or not selector:one_in(2 + count) then
                break
            end
        end
    end

    return cells, records, ids, protected
end

-- Tagged rune and exit maps use the same shared fitter as furniture,
-- but a separate source role. Remove a rejected candidate before the
-- next weighted draw so one impossible map cannot loop forever.
function vaults.place_tagged(ctx, cells, state, protected, tag)
    local player, context = selection_context(state)
    local candidates = {}

    vault_catalog.load()

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)
        local weight = weights.for_branch(definition,
            context.branch_id, context.depth,
            context.branch_bottom, context.absolute_depth)

        if definition.family == abyss.VAULT_FAMILY and
            definition.tags[tag] and weight > 0 and
            eligibility.tag(definition, context) then
            candidates[#candidates + 1] = {
                definition = definition,
                weight = weight,
            }
        end
    end

    for _ = 1, math.min(10, #candidates) do
        local total = 0

        for _, candidate in ipairs(candidates) do
            total = total + candidate.weight
        end

        local roll = ctx:random("placement", total)
        local selected

        for index, candidate in ipairs(candidates) do
            if roll < candidate.weight then
                selected = candidate.definition
                table.remove(candidates, index)
                break
            end

            roll = roll - candidate.weight
        end

        if not selected then
            error("Abyss tagged vault draw exceeded its pool")
        end

        -- A tagged dummy spends one source selection attempt without
        -- trying to fit a map. The next draw can still find a real vault.
        if not selected.tags.dummy then
            local okay, result = pcall(vaults.place_one, ctx, cells,
                vault_catalog.get(selected.id), player, {
                    protected = protected,
                })

            if okay then
                return result
            end

            if not fit_conflict(tostring(result)) then
                error(result)
            end

        end
    end

    return nil
end

return vaults
