-- Production DES parsing, hook dispatch, and nested SUBVAULT selection share
-- one local composition state. The fixture has two distinct region sizes.
local catalog = require("policy.generation.vaults.catalog")
local authored = require("policy.generation.layouts.authored")
local operations = require("policy.generation.vaults.operations")
local harness = require("tests.harness")

local test = {}

-- Always choose the first eligible helper; use history to remove repeats.
local function picker()
    local random = {}

    function random:roll()
        return 0
    end

    function random:one_in()
        return false
    end

    return random
end

-- Copy authored rows because operation processing is intentionally mutable.
local function cells_for(vault)
    local cells = {}

    for y, row in ipairs(vault.rows) do
        cells[y] = {}

        for x = 1, #row do
            cells[y][x] = row:sub(x, x)
        end
    end

    return cells
end

-- The nested child is committed first, then its parent, then the second
-- quadrant. The latter cannot reuse a non-duplicable NAME.
local function selected_helpers()
    local parent = catalog.get("fixture_parent")
    local cells = cells_for(parent)
    local _, ids = operations.apply(parent, cells, picker(), 0, {
        branch_id = "BRANCH_VAULTS",
        depth = 5,
        branch_bottom = 5,
        absolute_depth = 24,
    })

    harness.equal(#ids, 3, "three committed helper IDs")
    harness.equal(ids[1], "fixture_inner", "nested child is retained")
    harness.equal(ids[2], "fixture_a_helper", "first helper is retained")
    harness.equal(ids[3], "fixture_b_helper", "second helper is distinct")
    harness.equal(cells[1][1], "x", "nested child painted first region")
    harness.equal(cells[1][5], ".", "second region was painted")
end

-- Authored layouts must expose the helper IDs and occupied cells to the
-- later save and extra-vault owners, not only keep them inside operations.
local function authored_result()
    local context = {}

    function context:random_u64()
        return 120, 0
    end

    local result = authored.execute({
        ctx = context,
        definition = catalog.get("fixture_parent"),
        branch_id = "BRANCH_VAULTS",
        depth = 5,
        branch_bottom = 5,
        absolute_depth = 24,
    })

    harness.equal(#result.vault_ids, 3, "authored helper IDs reach caller")
    harness.truthy(next(result.protected) ~= nil,
        "authored occupied cells are protected")
end

-- Direct hooks must reject paints beyond the authored or assigned matrix.
local function bounded_paint()
    local bad = catalog.get("fixture_bad")
    local ok, message = pcall(operations.apply,
        bad, cells_for(bad), picker(), 0, {})

    harness.falsy(ok, "out-of-bounds paint must fail")
    harness.truthy(tostring(message):find("outside", 1, true),
        "failure identifies the local map boundary")
end

function test.run()
    catalog.load()
    selected_helpers()
    authored_result()
    bounded_paint()
end

return test
