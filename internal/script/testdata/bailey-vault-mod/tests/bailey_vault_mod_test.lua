-- A sparse child and a same-path hook replacement use production catalogs.
-- The test imports Bailey's real generator instead of duplicating selection.
local bailey = require("constants.bailey")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")
local level = require("policy.generation.bailey.level")
local terrain = require("constants.terrain")

local test = {}

-- This deterministic stream selects a chosen weighted slot while all
-- later random calls remain valid for map placement and source content.
local function context_for(slot)
    local context = { first = true }

    function context:random_u64()
        if slot == 0 then
            return 0, 0
        end

        if self.first then
            self.first = false

            return 0, slot
        end

        return 1, 1
    end

    function context:random(_, bound)
        return 1 % bound
    end

    return context
end

-- A new axe map joins by one DES file. Candidate IDs remain sorted, and
-- the existing first built-in choice remains stable under a sparse layer.
local function check_sparse_child()
    local candidates = level.candidates(bailey.AXE, {})
    local total = 0

    harness.equal(#candidates, 7, "sparse Bailey child joins axe pool")

    for index, candidate in ipairs(candidates) do
        if index > 1 then
            harness.truthy(candidates[index - 1].id < candidate.id,
                "Bailey mod pool must be in stable ID order")
        end

        total = total + candidate.weight
    end

    local first = level.generate(context_for(0), {
        theme = bailey.AXE,
    }).level

    harness.equal(first.vault_id, candidates[1].id,
        "sparse file changed the built-in first draw")

    local last = level.generate(context_for(total - 1), {
        theme = bailey.AXE,
    }).level

    harness.equal(last.vault_id, "zz_modded_bailey_training",
        "sparse child was not selected by the dispatcher")
    harness.equal(last.cells[last.entry_y + 1][last.entry_x + 1],
        terrain.DNGN_EXIT_BAILEY,
        "sparse child lost its return exit")
end

-- The source vampire castle still calls the same named local hook path.
-- Only the effective Lua file changes when a mod supplies that path.
local function check_hook_override()
    local floor = level.generate(context_for(0), {
        theme = bailey.POLEARM,
        layout_id = "bailey_polearm_vampire_castle_hellmonk",
    }).level
    local found = false

    for _, record in ipairs(floor.vault_records) do
        if record.kind == effects.MARKER and
            record.identity == "bailey_mod_hook_witness" then
            found = true
        end
    end

    harness.truthy(found, "same-path Bailey hook override did not run")
end

-- Both extension styles must coexist in the effective catalog.
function test.run()
    check_sparse_child()
    check_hook_override()
end

return test
