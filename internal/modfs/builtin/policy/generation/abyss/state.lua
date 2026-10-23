-- Theory of operation: the Abyss is one moving level over an unbounded
-- procedural coordinate plane. This table carries the clocks and borrowed
-- source floor needed to redraw only eligible cells after each action.
-- Generation returns a new table; the session owner saves it with the grid.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local catalog = require("policy.catalog")
local borrowed = require("policy.generation.abyss.borrowed")
local abyss = require("constants.abyss")

local state = {}

local state_draw_bound = 2147483648

local excluded_borrowed_branches = {
    [branches.BRANCH_VESTIBULE] = true,
    [branches.BRANCH_ABYSS] = true,
    [branches.BRANCH_SHOALS] = true,
}

-- Source branch iteration orders known floors by branch, then depth.
-- Excluding the Abyss avoids recursively sampling the mutable window.
local function borrowed_candidates(ctx)
    local candidates = {}

    for _, level_id in ipairs(ctx:level_ids()) do
        local branch_id = ctx:level_branch(level_id)

        if branch_id and not excluded_borrowed_branches[branch_id] then
            local branch = catalog.get(categories.BRANCHES, branch_id)

            candidates[#candidates + 1] = {
                level_id = level_id,
                branch_number = branch.numeric_id,
                depth = ctx:level_depth(level_id),
            }
        end
    end

    table.sort(candidates, function(left, right)
        if left.branch_number ~= right.branch_number then
            return left.branch_number < right.branch_number
        end

        return left.depth < right.depth
    end)

    return candidates
end

-- Copy the selected floor before the Abyss starts changing. The source
-- LevelLayout sanitizes the copy later; saving these rows ensures a loaded
-- game never borrows a different floor or advances RNG just to restore.
local function borrow_layout(ctx, level_id)
    local width, height = ctx:level_size(level_id)

    if not width or not height or width < 1 or height < 1 then
        error("Abyss borrowed floor has invalid dimensions")
    end

    local rows = {}

    for y = 0, height - 1 do
        local row = {}

        for x = 0, width - 1 do
            row[x + 1] = ctx:cell(level_id, x, y)
        end

        rows[y + 1] = row
    end

    return borrowed.prepare(ctx, rows)
end

-- The seed, not another random draw, chooses one already generated floor.
-- Source hash_with_seed returns a zero-based index into branch-order floors.
local function borrowed_floor(ctx, seed)
    local candidates = borrowed_candidates(ctx)

    if #candidates == 0 then
        error("Abyss needs an existing ordinary floor to borrow")
    end

    local index = ctx:hash_with_seed(#candidates, seed, 0)
    local chosen = candidates[index + 1]

    if not chosen then
        error("Abyss borrowed-floor hash is outside the catalog")
    end

    return chosen.level_id, borrow_layout(ctx, chosen.level_id)
end

-- Starting the pocket Abyss and ordinary banishment share source random
-- state but keep different return rules. Morph depth is independent from
-- the visible Abyss:1–7 branch depth.
function state.new(ctx, entry)
    entry = entry or {}

    local branch_depth = entry.branch_depth or 1
    local bottom = catalog.get(categories.BRANCHES,
        branches.BRANCH_ABYSS).depth

    if branch_depth < 1 or branch_depth > bottom or
        branch_depth % 1 ~= 0 then
        error("Abyss branch depth is outside its source range")
    end

    local world_x = ctx:random("abyss-state", state_draw_bound)
    local world_y = ctx:random("abyss-state", state_draw_bound)
    local seed = ctx:random("abyss-state", state_draw_bound)
    local morph_depth = ctx:random("abyss-state", state_draw_bound)
    local borrowed_level_id, borrowed_layout = borrowed_floor(ctx, seed)

    return {
        branch_depth = branch_depth,
        morph_depth = morph_depth,
        phase = 0,

        world_x = world_x,
        world_y = world_y,
        terrain_seed = seed,
        shift_count = 0,

        borrowed_level_id = borrowed_level_id,
        borrowed_layout = borrowed_layout,
        sample_queue = {},

        exit_xp = abyss.EXIT_XP_COST,
        exit_spawned = false,
        min_branch_depth = branch_depth,
        pocket_start = entry.pocket_start == true,
        return_site = entry.return_site,

        selected_map_ids = {},
        transit = {},
    }
end

return state
