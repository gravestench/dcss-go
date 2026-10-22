-- A sparse Ossuary map and a same-path Lua hook override use the same
-- layered discovery and source-position call path as built-in content.
local effects = require("constants.vault_effects")
local harness = require("tests.harness")
local ossuary = require("policy.generation.ossuary.level")
local terrain = require("constants.terrain")

local test = {}

-- A final weighted draw lands in the sparse map, independent of path
-- enumeration. The mod must still produce a usable reciprocal exit.
local function check_sparse_map()
    local candidates = ossuary.candidates({})
    local total = 0
    local previous = ""

    for _, candidate in ipairs(candidates) do
        harness.truthy(previous < candidate.id,
            "effective Ossuary pool is not sorted")

        previous = candidate.id
        total = total + candidate.weight
    end

    harness.equal(#candidates, 21, "sparse map joins source pool")

    local first = {}

    function first:random_u64()
        return 0, 0
    end

    function first:random()
        return 0
    end

    harness.equal(ossuary.generate(first, {}).level.vault_id,
        candidates[1].id,
        "the first built-in draw remains stable under a sparse layer")

    local context = { first_draw = true }

    function context:random_u64()
        if self.first_draw then
            self.first_draw = false

            return 0, total - 1
        end

        return 1, 1
    end

    local floor = ossuary.generate(context, {}).level

    harness.equal(floor.vault_id, "zz_modded_ossuary_gallery",
        "sparse map selected through production generator")
    harness.equal(floor.cells[floor.entry_y + 1]
        [floor.entry_x + 1], terrain.DNGN_EXIT_OSSUARY,
        "sparse map retains its return gate")
end

-- The override owns an existing hook path, so an explicit layout request
-- must see its typed witness instead of the bundled loot declaration.
local function check_hook_override()
    local context = {}

    function context:random_u64()
        return 1, 1
    end

    function context:random(_, bound)
        return 1 % bound
    end

    local floor = ossuary.generate(context, {
        layout_id = "ossuary_the_hunt_dpeg",
    }).level
    local found = false

    for _, record in ipairs(floor.vault_records) do
        if record.kind == effects.MARKER and
            record.identity == "ossuary_mod_hook_witness" then
            found = true
        end
    end

    harness.truthy(found, "same-path hook override did not run")
end

-- Both extension styles must survive one effective catalog load.
function test.run()
    check_sparse_map()
    check_hook_override()
end

return test
