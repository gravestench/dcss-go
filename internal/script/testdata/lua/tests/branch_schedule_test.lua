-- Ordinary branch positions are run state, not file discovery order.
-- The production catalog supplies every branch range and parent edge.
local branches = require("ids.branches")
local harness = require("tests.harness")
local levels = require("policy.generation.branch_levels")
local schedule = require("policy.generation.branch_schedule")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")

local test = {}

-- Zero draws choose the first legal depth and first member of each pair.
-- This fixture uses the production chooser without a Go game or duplicate
-- branch schema, so seed-order expectations stay close to real Lua rules.
local function zero_random()
    local context = {
        calls = {},
    }

    function context:random(stream, bound)
        self.calls[#self.calls + 1] = {
            stream = stream,
            bound = bound,
        }

        return 0
    end

    return context
end

-- IDs derive from catalog numeric IDs and local depth, never Lua file names.
local function stable_level_ids()
    harness.equal(levels.id(branches.BRANCH_DUNGEON, 1), 1,
        "Dungeon ID remains 1")
    harness.equal(levels.id(branches.BRANCH_LAIR, 1), 501,
        "Lair first floor ID")
    harness.equal(levels.id(branches.BRANCH_ORC, 2), 202,
        "Orc second floor ID")

    local okay = pcall(levels.id, branches.BRANCH_LAIR, 6)

    harness.falsy(okay, "Lair accepted depth beyond its catalog bottom")
end

-- The two source swap pairs each admit one sibling. Rootless portals,
-- Ziggurats, and Hell subbranches never become ordinary entrances.
local function chosen_schedule_matches_catalog()
    local context = zero_random()
    local chosen = schedule.choose(context)

    schedule.validate(chosen)
    harness.equal(chosen.water_branch_id, branches.BRANCH_SWAMP,
        "first water choice")
    harness.equal(chosen.poison_branch_id, branches.BRANCH_SNAKE,
        "first poison choice")
    harness.equal(chosen.entries[branches.BRANCH_LAIR].parent_depth, 8,
        "Lair source entrance minimum")
    harness.equal(chosen.entries[branches.BRANCH_ORC].parent_depth, 9,
        "Orc source entrance minimum")
    harness.falsy(chosen.entries[branches.BRANCH_SHOALS],
        "disabled water branch has no entrance")
    harness.falsy(chosen.entries[branches.BRANCH_SPIDER],
        "disabled poison branch has no entrance")
    harness.falsy(chosen.entries[branches.BRANCH_ZIGGURAT],
        "no-x-level Ziggurat became ordinary")
    harness.falsy(chosen.entries[branches.BRANCH_VESTIBULE],
        "rootless Hell entrance became ordinary")
    harness.falsy(chosen.entries[branches.BRANCH_DIS],
        "Hell child of rootless Vestibule became ordinary")

    local lair_entries = schedule.entries(chosen,
        branches.BRANCH_DUNGEON, 8)

    harness.equal(lair_entries[1].branch_id, branches.BRANCH_LAIR,
        "Dungeon:8 names Lair")
    harness.truthy(#context.calls > 2,
        "schedule consumed source range draws")
end

-- Reversing discovery order cannot change a seeded schedule. The chooser
-- sorts effective IDs before spending the dedicated schedule stream.
local function discovery_order_does_not_change_selection()
    local expected = schedule.choose(zero_random())
    local original_all = catalog.all

    catalog.all = function(category)
        local definitions = original_all(category)

        if category == categories.BRANCHES then
            local reversed = {}

            for index = #definitions, 1, -1 do
                reversed[#reversed + 1] = definitions[index]
            end

            return reversed
        end

        return definitions
    end

    local okay, actual = pcall(schedule.choose, zero_random())
    catalog.all = original_all

    harness.truthy(okay, "reverse catalog traversal failed")

    for branch_id, entry in pairs(expected.entries) do
        harness.equal(actual.entries[branch_id].parent_depth,
            entry.parent_depth, branch_id .. " seed changed with load order")
    end
end

-- Saved schedules cannot move an entrance outside its source range or
-- resurrect both siblings after a restore or a modded JSON edit.
local function tampering_is_rejected()
    local chosen = schedule.choose(zero_random())
    local original = chosen.entries[branches.BRANCH_LAIR].parent_depth

    chosen.entries[branches.BRANCH_LAIR].parent_depth = 1
    local okay = pcall(schedule.validate, chosen)
    chosen.entries[branches.BRANCH_LAIR].parent_depth = original

    harness.falsy(okay, "invalid saved entrance depth was accepted")

    chosen.entries[branches.BRANCH_SHOALS] = {
        parent_id = branches.BRANCH_LAIR,
        parent_depth = 2,
    }
    okay = pcall(schedule.validate, chosen)

    harness.falsy(okay, "both water branches were accepted")
end

-- Exercise all source-backed schedule contracts in one isolated Lua VM.
function test.run()
    stable_level_ids()
    chosen_schedule_matches_catalog()
    discovery_order_does_not_change_selection()
    tampering_is_rejected()
end

return test
