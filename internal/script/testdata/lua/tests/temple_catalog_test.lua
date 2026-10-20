-- Temple maps are effective layered DES files. This test reads the same
-- catalog that live generation uses, so it cannot drift into a test copy.
local catalog = require("policy.generation.temple.catalog")
local directives = require("constants.vault_directives")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")

local test = {}

-- The source's only conditional entry chooses one of two water patterns.
-- Run its named hook from the parsed DES operation, not a test-only copy.
local function pool_entry_pattern(draw, expected)
    local definition = catalog.entry("temple_pool_b")
    local emitted = {}
    local method

    for _, operation in ipairs(definition.operations) do
        if operation.kind == directives.HOOK_RUN then
            method = operation.argument
            break
        end
    end

    harness.truthy(method, "pool entry has its source-position hook")

    local api = {}

    function api:roll(bound)
        harness.equal(bound, 10, "source pool chance denominator")

        return draw
    end

    function api:emit(kind, argument)
        emitted[#emitted + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    hooks.run(definition, method, api)
    harness.equal(#emitted, expected,
        "pool entry emits the selected source directive group")
    harness.equal(emitted[1].kind, directives.SHUFFLE,
        "source shuffle precedes substitutions")
end

-- The source file has 53 Dungeon entries and 90 main maps. Count the
-- effective files so a missing definition is visible before generation.
function test.run()
    catalog.load()

    harness.equal(#catalog.entry_ids(), 53,
        "all Dungeon Temple entries are present")
    harness.equal(catalog.static_count(), 43,
        "all script-free main Temple maps are present")
    harness.equal(#catalog.main_ids(), 90,
        "all source main maps join the Temple catalog")
    harness.truthy(catalog.main("nicolae_temple_stand_before_the_council"),
        "the corrected six-altar map is available")

    for _, id in ipairs(catalog.entry_ids()) do
        local definition = catalog.entry(id)

        harness.truthy(definition.tags.temple_entry,
            id .. " remains a Temple entry")
        harness.truthy(#definition.rows > 0,
            id .. " retains authored map rows")
    end

    pool_entry_pattern(0, 2)
    pool_entry_pattern(9, 3)
end

return test
