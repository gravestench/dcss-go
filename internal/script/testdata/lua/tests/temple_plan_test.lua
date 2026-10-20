-- Temple's selected map and god partition are run state. These tests use
-- the production catalog and plan, so no test-only map schema can drift.
local catalog = require("policy.generation.temple.catalog")
local harness = require("tests.harness")
local plan = require("policy.generation.temple.plan")
local streams = require("constants.rng_streams")

local test = {}

-- Narrow candidate selection without copying map records. The real
-- catalog still supplies the rare map's tags, weight, and source ID.
local function only_map(id)
    local selected = {}

    function selected.main_ids()
        return { id }
    end

    function selected.main(requested)
        if requested == id then
            return catalog.main(id)
        end

        return nil
    end

    return selected
end

-- A scripted draw sequence makes the rare branch and both ordinary bands
-- reproducible without tying a test to Go's RNG implementation.
local function draws(values)
    local context = {
        index = 0,
    }

    function context:random(stream, bound)
        harness.equal(stream, streams.TEMPLE_PLAN,
            "Temple uses its own persisted draw stream")

        self.index = self.index + 1
        local value = values[self.index] or 0

        harness.truthy(value < bound, "Temple draw stays inside its bound")

        return value
    end

    return context
end

-- Every overflow god belongs to one saved Dungeon placement. The schedule
-- draws at character creation, so revisiting a floor cannot regroup gods.
local function assert_overflow_schedule(chosen)
    local remaining = {}

    for _, id in ipairs(chosen.overflow_god_ids) do
        remaining[id] = true
    end

    harness.truthy(type(chosen.overflow_schedule) == "table",
        "Temple saves its Dungeon overflow schedule")

    for _, group in ipairs(chosen.overflow_schedule) do
        harness.truthy(group.depth >= 3 and group.depth <= 10,
            "overflow depth is within the source D:3-10 band")
        harness.truthy(#group.god_ids > 0,
            "overflow group has at least one god")

        for _, id in ipairs(group.god_ids) do
            harness.truthy(remaining[id],
                "overflow god is scheduled once")
            remaining[id] = nil
        end
    end

    harness.falsy(next(remaining),
        "every overflow god has a scheduled map")
end

-- Selected gods must form a complete partition with no duplicates. The
-- validator also catches a changed map, count, or effective god pool.
function test.run()
    catalog.load()

    local ordinary = plan.choose(draws({ 1, 0, 8, 8 }), catalog)

    harness.equal(ordinary.altar_count, 13,
        "lower source band reaches its upper edge")
    harness.falsy(catalog.main(ordinary.map_id).tags.temple_rare,
        "ordinary draw cannot select a rare map")
    plan.validate(ordinary, catalog)
    assert_overflow_schedule(ordinary)

    local upper = plan.choose(draws({ 1, 1, 0, 0 }), catalog)

    harness.equal(upper.altar_count, 14,
        "upper source band reaches its lower edge")

    local rare = plan.choose(draws({ 0 }), catalog)

    harness.truthy(catalog.main(rare.map_id).tags.temple_rare,
        "one-in-one-hundred draw selects only rare maps")
    plan.validate(rare, catalog)
    assert_overflow_schedule(rare)

    local empty = plan.choose(draws({ 0 }),
        only_map("ebering_the_none_and_only"))

    harness.equal(empty.altar_count, 0,
        "a rare empty Temple keeps all gods in overflow")
    harness.equal(#empty.main_god_ids, 0,
        "the empty Temple has no main altar identities")

    local complete = plan.choose(draws({ 0 }),
        only_map("hellmonk_choose_your_character"))

    harness.equal(complete.altar_count, 22,
        "a rare full Temple can contain the whole eligible pantheon")
    harness.equal(#complete.overflow_god_ids, 0,
        "the full Temple leaves no overflow gods")
    harness.equal(#complete.overflow_schedule, 0,
        "the full Temple schedules no overflow maps")

    local missing = plan.choose(draws({ 0 }), catalog)

    missing.overflow_schedule[1].god_ids[1] = missing.main_god_ids[1]
    harness.falsy(pcall(plan.validate, missing, catalog),
        "a saved schedule cannot substitute a Temple god")

    local wrong_depth = plan.choose(draws({ 0 }), catalog)

    wrong_depth.overflow_schedule[1].depth = 2
    harness.falsy(pcall(plan.validate, wrong_depth, catalog),
        "a saved overflow group must stay within D:3-10")

    ordinary.main_god_ids[1] = ordinary.main_god_ids[2]
    local okay = pcall(plan.validate, ordinary, catalog)

    harness.falsy(okay, "duplicate saved Temple god was accepted")

    upper.map_id = "missing_temple_map"
    okay = pcall(plan.validate, upper, catalog)

    harness.falsy(okay, "missing saved Temple map was accepted")
end

return test
