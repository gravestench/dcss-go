-- Theory of operation: Ice Cave has no procedural terrain shell. One
-- effective source DES child covers its entire temporary level. The saved
-- entrance difficulty changes its hooks, then the staged portal owns commit.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local eligibility = require("policy.generation.vaults.eligibility")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local levels = require("policy.generation.branch_levels")
local placement = require("policy.generation.vaults.placement")
local terrain = require("constants.terrain")
local transporters = require("policy.generation.transporters")
local vaults = require("policy.generation.vaults.catalog")
local weights = require("policy.generation.vaults.weight")

local level = {}

-- Sort stable IDs before drawing, so a mod layer's file order cannot
-- alter seeded selection. Only positive effective weights join the pool.
function level.candidates(player)
    vaults.load()

    local context = {
        branch_id = branches.BRANCH_ICE_CAVE,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 15,
        player = player,
    }
    local maps = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.family == "ice_cave" and
            eligibility.depth(definition, context) then
            local weight = weights.for_branch(definition,
                context.branch_id, context.depth,
                context.branch_bottom, context.absolute_depth)

            if weight > 0 then
                maps[#maps + 1] = {
                    id = id,
                    weight = weight,
                }
            end
        end
    end

    table.sort(maps, function(left, right)
        return left.id < right.id
    end)

    return maps
end

-- The authored exit is the safe arrival anchor. Starting at an arbitrary
-- plain cell can strand a player inside a sealed chamber.
local function arrival_exit(cells)
    for y, row in ipairs(cells) do
        for x, feature in ipairs(row) do
            if feature == terrain.DNGN_EXIT_ICE_CAVE then
                return {
                    x = x - 1,
                    y = y - 1,
                }
            end
        end
    end

    error("Ice Cave layout has no live return exit")
end

-- A requested ID still has to exist in the effective positive-weight
-- pool. Ordinary entry makes one weighted draw after this validation.
local function choose(builder, player, requested_id)
    local maps = level.candidates(player)
    local total = 0

    if requested_id then
        for _, map in ipairs(maps) do
            if map.id == requested_id then
                return vaults.get(map.id)
            end
        end

        error("requested Ice Cave layout is not eligible")
    end

    for _, map in ipairs(maps) do
        total = total + map.weight
    end

    if total == 0 then
        error("Ice Cave has no eligible layout")
    end

    local draw = builder:roll(total)

    for _, map in ipairs(maps) do
        if draw < map.weight then
            return vaults.get(map.id)
        end

        draw = draw - map.weight
    end

    error("Ice Cave layout draw exceeded the catalog")
end

-- Generate without installing a floor or mutating the current game.
-- Each hook reads this one saved boolean through the normal vault API.
function level.generate(ctx, input)
    if type(input.hard) ~= "boolean" then
        error("Ice Cave generation requires saved difficulty")
    end

    local player = {
        branch_id = branches.BRANCH_ICE_CAVE,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 15,
        species_id = input.species_id,
        name = input.player_name,
        settings = {
            ice_cave_hard = input.hard,
        },
    }
    local builder = grid.new(ctx)
    local definition = choose(builder, player, input.layout_id)
    local placed = placement.place(ctx, builder, definition, player, {
        whole_level = true,
    })
    local cells = features.decode_source_rows(builder:rows())
    local records = features.apply_vault_terrain(cells,
        placed.records, ctx, 1)
    local entry = arrival_exit(cells)
    local ids = { placed.id }

    for _, id in ipairs(placed.vault_ids or {}) do
        ids[#ids + 1] = id
    end

    local result = {
        level = {
            id = levels.id(branches.BRANCH_ICE_CAVE, 1),
            branch_id = branches.BRANCH_ICE_CAVE,
            local_depth = 1,
            cells = cells,
            stairs = {},
            entry_x = entry.x,
            entry_y = entry.y,
            initial_monsters = 0,
            vault_id = placed.id,
            vault_ids = ids,
            vault_records = records,
        },
    }

    -- The statue garden's source and landing markers must become actual
    -- linked cells before the staged floor or its save can be accepted.
    transporters.resolve(result.level)

    return result
end

return level
