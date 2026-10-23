-- Theory of operation: the effective DES catalog owns ten full Gauntlet
-- parent maps. A source-weighted draw chooses one, nested SUBVAULT calls
-- fill its arena and minotaur slots, and the generic transporter resolver
-- links every numbered route before the staged floor is installed.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local catalog = require("policy.catalog")
local eligibility = require("policy.generation.vaults.eligibility")
local effects = require("constants.vault_effects")
local features = require("content.terrain_features")
local gauntlet = require("constants.gauntlet")
local grid = require("policy.generation.grid")
local levels = require("policy.generation.branch_levels")
local placement = require("policy.generation.vaults.placement")
local terrain = require("constants.terrain")
local transporters = require("policy.generation.transporters")
local vaults = require("policy.generation.vaults.catalog")
local weights = require("policy.generation.vaults.weight")

local level = {}

-- The exit helper must contribute its own live arch. Parent return arches
-- cannot rescue a player carried by the final one-way transporter into a
-- minotaur room with a missing or incorrectly mapped exit declaration.
local function verify_boss_exit(placed, cells)
    local boss_id = nil

    for _, id in ipairs(placed.vault_ids or {}) do
        if vaults.get(id).tags[gauntlet.EXIT_TAG] then
            if boss_id then
                error("Gauntlet has more than one boss-room exit helper")
            end

            boss_id = id
        end
    end

    local arches = 0

    for _, record in ipairs(placed.records or {}) do
        if record.vault_id == boss_id and
            record.kind == effects.FEATURE and
            record.identity == gauntlet.EXIT_FEATURE and
            cells[record.y + 1][record.x + 1] ==
                terrain.DNGN_EXIT_GAUNTLET then
            arches = arches + 1
        end
    end

    if arches ~= 1 then
        error("Gauntlet has no live boss-room return arch")
    end
end

-- The parent MAP's own < is the entry-side return arch. A selected exit
-- helper also contains <, so scanning the finished grid would confuse the
-- two on layouts where the boss room happens to be nearer the top.
local function arrival_exit(definition, placed, cells)
    for local_y, row in ipairs(definition.rows) do
        for local_x = 1, #row do
            if row:sub(local_x, local_x) == "<" then
                local x = placed.bounds.x + local_x - 1
                local y = placed.bounds.y + local_y - 1

                if cells[y + 1] and
                    cells[y + 1][x + 1] ==
                        terrain.DNGN_EXIT_GAUNTLET then
                    return { x = x, y = y }
                end
            end
        end
    end

    error("Gauntlet parent has no live entry-side return arch")
end

-- Mods can add or replace a whole parent by path. Sorting by stable
-- source ID makes file enumeration irrelevant to a seeded choice.
function level.candidates(player)
    vaults.load()
    local branch = catalog.get(categories.BRANCHES,
        branches.BRANCH_GAUNTLET)
    local context = {
        branch_id = branches.BRANCH_GAUNTLET,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = branch.absolute_depth,
        player = player,
    }
    local candidates = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.family == gauntlet.DESTINATION_FAMILY and
            eligibility.depth(definition, context) then
            local weight = weights.for_branch(definition,
                context.branch_id, context.depth,
                context.branch_bottom, context.absolute_depth)

            if weight > 0 then
                candidates[#candidates + 1] = {
                    id = id,
                    weight = weight,
                }
            end
        end
    end

    table.sort(candidates, function(left, right)
        return left.id < right.id
    end)

    return candidates
end

-- An explicit layout supports tests and authored mod scenarios; ordinary
-- play spends one bounded draw from the staged builder RNG.
local function choose(builder, player, requested_id)
    local candidates = level.candidates(player)
    local total = 0

    for _, candidate in ipairs(candidates) do
        if requested_id and candidate.id == requested_id then
            return vaults.get(candidate.id)
        end

        total = total + candidate.weight
    end

    if requested_id then
        error("requested Gauntlet layout is not eligible")
    end

    if total == 0 then
        error("Gauntlet has no eligible parent layout")
    end

    local draw = builder:roll(total)

    for _, candidate in ipairs(candidates) do
        if draw < candidate.weight then
            return vaults.get(candidate.id)
        end

        draw = draw - candidate.weight
    end

    error("Gauntlet layout draw exceeded the catalog")
end

-- Population sees one uninstalled floor. The generic portal transaction
-- can discard it whole if a marker, minotaur, or item cannot materialize.
function level.generate(ctx, input)
    local branch = catalog.get(categories.BRANCHES,
        branches.BRANCH_GAUNTLET)
    local player = {
        branch_id = branches.BRANCH_GAUNTLET,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = branch.absolute_depth,
        species_id = input.species_id,
        name = input.player_name,
    }
    local builder = grid.new(ctx)
    local definition = choose(builder, player, input.layout_id)
    local placed = placement.place(ctx, builder, definition, player, {
        whole_level = true,
    })
    local cells = features.decode_source_rows(builder:rows())
    local records = features.apply_vault_terrain(cells,
        placed.records, ctx, 1)
    local entry = arrival_exit(definition, placed, cells)

    verify_boss_exit(placed, cells)

    local ids = { placed.id }

    for _, id in ipairs(placed.vault_ids or {}) do
        ids[#ids + 1] = id
    end

    local staged = {
        id = levels.id(branches.BRANCH_GAUNTLET, 1),
        branch_id = branches.BRANCH_GAUNTLET,
        local_depth = 1,
        cells = cells,
        stairs = {},
        entry_x = entry.x,
        entry_y = entry.y,
        initial_monsters = 0,
        vault_id = placed.id,
        vault_ids = ids,
        vault_records = records,
    }

    transporters.resolve(staged)

    return { level = staged }
end

return level
