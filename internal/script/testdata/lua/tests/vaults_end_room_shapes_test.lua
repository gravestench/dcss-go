-- Source room helpers paint the rectangle assigned by their parent map.
-- The test uses the production DES parser and helper catalog, then checks
-- the resulting local cells before whole-level placement can rotate them.
local branches = require("ids.branches")
local des = require("policy.generation.vaults.des")
local harness = require("tests.harness")
local operations = require("policy.generation.vaults.operations")

local test = {}

-- Build a parent placeholder at each requested source size. The helpers'
-- own empty MAPs supply no dimensions, so the parent is authoritative.
local function parent_for(width, height)
    local rows = {}

    for _ = 1, height do
        rows[#rows + 1] = string.rep("R", width)
    end

    local source = table.concat({
        "NAME: source_room_shape_fixture",
        "SUBVAULT: R : vaults_end_room",
        "MAP",
        table.concat(rows, "\n"),
        "ENDMAP",
    }, "\n")
    local map = des.parse("vaults/fixture/source_room_shape_fixture.des",
        source)
    local cells = {}

    for y, row in ipairs(map.rows) do
        cells[y] = {}

        for x = 1, #row do
            cells[y][x] = row:sub(x, x)
        end
    end

    return map, cells
end

-- The first eligible room is the border helper; the second is diamond.
-- Draw only at the helper-pool decision, leaving source substitutions on
-- their own deterministic zero draws.
local function picker(helper_draw)
    local random = {}

    function random:roll(bound)
        if bound == 30 then
            return helper_draw
        end

        return 0
    end

    function random:one_in()
        return false
    end

    return random
end

-- Check one rectangular size and one square size to catch code that
-- accidentally assumes fixed helper dimensions or transposes coordinates.
local function painted_shape(width, height, helper_draw, expected_id)
    local map, cells = parent_for(width, height)
    local _, ids = operations.apply(map, cells, picker(helper_draw), 0, {
        branch_id = branches.BRANCH_VAULTS,
        depth = 5,
        branch_bottom = 5,
        absolute_depth = 23,
    })

    harness.equal(ids[1], expected_id, "selected source room helper")
    harness.equal(#cells, height, "helper local height")
    harness.equal(#cells[1], width, "helper local width")

    return cells
end

function test.run()
    local border = painted_shape(6, 5, 0, "vaults_end_room_border")

    harness.equal(border[1][1], ".", "border corner is floor")
    harness.equal(border[5][6], ".", "far border corner is floor")
    harness.truthy(border[3][3] ~= ".", "border interior has loot")

    local diamond = painted_shape(4, 3, 10, "vaults_end_room_diamond")

    harness.equal(diamond[1][1], "$", "even parity is coin")
    harness.equal(diamond[1][2], ".", "odd parity is floor")
    harness.equal(diamond[3][3], "$", "far even parity is coin")
end

return test
