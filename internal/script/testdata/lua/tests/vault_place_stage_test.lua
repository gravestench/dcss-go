-- Explicit PLACE maps get one weighted attempt before ordinary minivaults.
local branches = require("ids.branches")
local des = require("policy.generation.vaults.des")
local harness = require("tests.harness")
local place = require("policy.generation.vaults.place")
local used = require("policy.generation.vaults.used")

local test = {}

-- Parse through the production DES grammar so these fixtures do not
-- duplicate a hand-built vault schema that might drift from real maps.
local function definition(id, place_rule, directives)
    return des.parse("vaults/test/" .. id .. ".des", table.concat({
        "NAME: " .. id,
        "PLACE: " .. place_rule,
        directives or "TAGS: extra",
        "MAP",
        "...",
        "ENDMAP",
    }, "\n"))
end

-- A PLACE rule is distinct from DEPTH: its branch, bottom marker, and
-- exclusion decide eligibility without adding a map to depth draws.
local function explicit_place_filter()
    local dungeon = definition("place_dungeon", "D:4")
    local bottom = definition("place_bottom", "D:$")
    local vetoed = definition("place_vetoed", "D:4, !D:4")
    local regular = definition("place_regular", "D:4", "ORIENT: float")
    local context = {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 4,
        branch_bottom = 15,
        layout_family = "rooms",
        used = used.new({}),
    }
    local candidates = place.candidates(context, {
        dungeon, bottom, vetoed, regular,
    })

    harness.equal(#candidates, 1, "only the matching minivault enters PLACE")
    harness.equal(candidates[1].definition.id, dungeon.id,
        "PLACE selects its authored floor")

    context.depth = 15
    candidates = place.candidates(context, { dungeon, bottom })

    harness.equal(#candidates, 1, "bottom marker matches branch bottom")
    harness.equal(candidates[1].definition.id, bottom.id,
        "bottom PLACE map wins its floor")
end

-- The source selector chooses by weight in stable ID order, suppresses
-- a selected dummy, and never spends a draw for an empty pool.
local function weighted_choice_and_dummy()
    local first = definition("place_a", "D:4", "WEIGHT: 2")
    local last = definition("place_z", "D:4", "WEIGHT: 3")
    local dummy = definition("place_dummy", "D:4", "TAGS: dummy")
    local random = {}
    local calls = 0

    function random:roll(bound)
        calls = calls + 1

        return bound - 1
    end

    local context = {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 4,
        branch_bottom = 15,
        used = used.new({}),
    }
    local candidates = place.candidates(context, { last, first })

    harness.equal(place.choose(random, candidates).id, last.id,
        "last point selects the final weighted ID")
    harness.equal(calls, 1, "one bounded weighted draw")

    candidates = place.candidates(context, { dummy })

    harness.falsy(place.choose(random, candidates),
        "a selected dummy suppresses placement")
    harness.falsy(place.choose(random, {}), "empty PLACE pool is harmless")
    harness.equal(calls, 2, "empty pool spends no draw")
end

-- One successful explicit placement consumes its name and joins the same
-- saved history as later depth maps; an extra tag does not add a second
-- PLACE attempt.
local function one_attempt_records_success()
    local vault = definition("place_once", "D:4")
    local catalog = require("policy.generation.vaults.catalog")
    local original_candidates = place.candidates
    local original_get = catalog.get
    local context = {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 4,
        branch_bottom = 15,
        used = used.new({}),
    }
    local builder = {}
    local attempts = 0
    local placed = {}

    -- Patch only catalog discovery: the fixture is still parsed by the
    -- real DES reader and is placed by the real PLACE stage below.
    function place.candidates()
        return original_candidates(context, { vault })
    end

    function catalog.get(id)
        harness.equal(id, vault.id, "selected PLACE ID")

        return vault
    end

    function builder:roll()
        return 0
    end

    local function fit(_, _, selected)
        attempts = attempts + 1

        return {
            id = selected.id,
        }
    end

    local primary = place.place(nil, builder, context, placed, fit)

    place.candidates = original_candidates
    catalog.get = original_get

    harness.equal(primary, vault.id, "successful PLACE becomes primary")
    harness.equal(attempts, 1, "extra PLACE map still gets one attempt")
    harness.equal(context.used:ids()[1], vault.id,
        "successful PLACE enters saved vault history")
    harness.equal(placed[1].id, vault.id,
        "PLACE uses the shared placement callback")
end

-- The parser and weighted policy share the same source-derived map
-- semantics before a real branch catalog is imported.
function test.run()
    explicit_place_filter()
    weighted_choice_and_dummy()
    one_attempt_records_success()
end

return test
