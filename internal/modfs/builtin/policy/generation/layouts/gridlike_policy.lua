-- Theory of operation: Gridlike uses one cell tiler with branch-specific
-- choices for room corners, doors, corridor width, and seed grouping.
-- The source makes these choices once before assigning any cell tiles.
local branches = require("ids.branches")
local subdivision = require("policy.generation.layouts.subdivision")

local policy = {}

-- Begin with source defaults. Local depth controls the ordinary corridor
-- width draw before a branch overrides it with its own range.
local function defaults(builder, depth)
    return {
        doors = builder:one_in(3),
        corners = false,
        regular_grid = false,
        maxcorridor = builder:roll(math.ceil(depth / 9)) + 1,
        random_rooms = false,
        collapse_rooms = true,
        corridor_doors = true,
        big_corridors = false,
        mid_doors = false,
    }
end

-- Crypt and Elf use regular corridor centers and clipped room corners.
-- Crypt also keeps wider passages between its enclosed rooms.
local function fixed_branch(builder, branch, choices)
    if branch == branches.BRANCH_CRYPT then
        choices.corners = true
        choices.regular_grid = true
        choices.collapse_rooms = false
        choices.big_corridors = true
        choices.maxcorridor = subdivision.range(builder, 2, 3)
    elseif branch == branches.BRANCH_ELF then
        choices.corners = true
        choices.doors = false
        choices.regular_grid = true
        choices.maxcorridor = subdivision.range(builder, 1, 2)
        choices.mid_doors = true
    end
end

-- Snake and Lair allow scattered room seeds. Lair's passages have no
-- doors; Snake chooses its corridor door rule independently each floor.
local function lair_branch(builder, branch, choices)
    if branch == branches.BRANCH_SNAKE then
        choices.corners = true
        choices.corridor_doors = builder:one_in(2)
        choices.random_rooms = builder:one_in(2)
        choices.maxcorridor = subdivision.range(builder, 1, 4)
    elseif branch == branches.BRANCH_LAIR then
        choices.doors = false
        choices.corridor_doors = false
        choices.corners = builder:one_in(2)
        choices.maxcorridor = 4
        choices.random_rooms = true
    end
end

-- Pan varies most options per floor instead of choosing a single fixed
-- style for the whole branch; all draws stay on the layout RNG stream.
local function pan_branch(builder, branch, choices)
    if branch ~= branches.BRANCH_PANDEMONIUM then
        return
    end

    choices.regular_grid = builder:one_in(2)
    choices.doors = false
    choices.corridor_doors = false
    choices.collapse_rooms = builder:one_in(2)
    choices.corners = builder:one_in(2)
    choices.random_rooms = builder:one_in(2)
    choices.maxcorridor = subdivision.range(builder, 1, 4)
    choices.mid_doors = builder:one_in(2)
end

-- Return one mutable policy instance for this layout, never shared mutable
-- module state. The renderer reads it without editing branch decisions.
function policy.choose(builder, branch, depth)
    local choices = defaults(builder, depth)

    fixed_branch(builder, branch, choices)
    lair_branch(builder, branch, choices)
    pan_branch(builder, branch, choices)

    return choices
end

return policy
