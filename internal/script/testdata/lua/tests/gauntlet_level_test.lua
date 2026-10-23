-- The Gauntlet generator must stage one complete, decoded floor with
-- transporters resolved before the portal transaction installs it.
local harness = require("tests.harness")
local levels = require("policy.generation.branch_levels")
local branches = require("ids.branches")
local terrain = require("constants.terrain")
local effects = require("constants.vault_effects")
local generator = require("policy.generation.gauntlet.level")

local test = {}

-- Reuse the builder's random contract rather than repeating the parent
-- selection algorithm in this test fixture.
local function seeded_context(seed)
    local value = seed
    local context = {}

    function context:random_u64()
        value = (value * 48271) % 2147483647

        return 0, value
    end

    function context:random(_stream, bound)
        self:random_u64()

        return value % bound
    end

    return context
end

-- A source < is the arrival and return arch. A staged floor also keeps
-- its complete source identity for save, inspect, and mod diagnosis.
function test.run()
    local result = generator.generate(seeded_context(47), {
        layout_id = "gammafunk_gauntlet_branching",
    })
    local level = result.level

    harness.equal(level.id,
        levels.id(branches.BRANCH_GAUNTLET, 1),
        "Gauntlet floor identity")
    harness.equal(level.branch_id, branches.BRANCH_GAUNTLET,
        "Gauntlet branch identity")
    harness.equal(level.cells[level.entry_y + 1][level.entry_x + 1],
        terrain.DNGN_EXIT_GAUNTLET,
        "arrival cell must be a return arch")
    harness.truthy(#level.vault_ids > 1,
        "parent did not place arena and exit helpers")

    for _, record in ipairs(level.vault_records) do
        if record.kind == effects.ITEM or record.kind == effects.MONSTER then
            harness.truthy(record.source and record.source ~= " ",
                string.format("unplaced %s from %s at %d,%d; target=%s pending=%s directive=%s identity=%s line=%s",
                    record.kind, tostring(record.vault_id), record.x, record.y,
                    tostring(record.targets), tostring(record.pending),
                    tostring(record.directive), tostring(record.identity),
                    tostring(record.line)))
        end
    end
end

return test
