-- This test reads the same effective DES files the game selects. The
-- pinned digest catches changed MAP rows without loading the C++ checkout.
local branches = require("ids.branches")
local des = require("policy.generation.vaults.des")
local eligibility = require("policy.generation.vaults.eligibility")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")

local test = {}

-- Sorting source IDs makes the corpus check independent of VFS enumeration.
local function map_digest(paths)
    local maps = {}

    for _, path in ipairs(paths) do
        local map = des.parse(path, mod.read(path))

        maps[#maps + 1] = map.id .. ":" ..
            table.concat(map.rows, "\n")
    end

    table.sort(maps)

    local hash = 0

    for byte in (table.concat(maps, "\n")):gmatch(".") do
        hash = (hash * 31 + string.byte(byte)) % 4294967296
    end

    return hash
end

-- The entry's common hook runs after selection, so the tags and chance
-- have to be visible to the selector in the parsed definition itself.
local function check_entry(path)
    local map = des.parse(path, mod.read(path))

    harness.truthy(map.tags.uniq_icecv and
        map.tags.chance_icecave,
        map.id .. " lacks the source Ice Cave tags")
    harness.equal(map.chances[1].chance, 500,
        map.id .. " source chance")
    harness.truthy(#map.operations > 0,
        map.id .. " lost its source-position hook")

    hooks.validate(map)

    return map
end

-- The destination has no ordinary item or monster generation. All authored
-- content comes from the map and its named conditional hooks.
local function check_destination(path)
    local map = des.parse(path, mod.read(path))

    harness.equal(map.orientation, "encompass",
        map.id .. " source orientation")
    harness.truthy(map.tags.no_item_gen and
        map.tags.no_monster_gen,
        map.id .. " lost its authored population boundary")

    hooks.validate(map)
end

-- A map with a narrower source DEPTH remains restricted after the common
-- helper adds its selection tags. These counts include the two weight-5
-- out-of-depth entries only where their own depth allows them.
local function eligible_count(entries, branch, depth, bottom)
    local count = 0

    for _, map in ipairs(entries) do
        if eligibility.depth(map, {
            branch_id = branch,
            depth = depth,
            branch_bottom = bottom,
            absolute_depth = depth,
        }) then
            count = count + 1
        end
    end

    return count
end

-- Check the whole source domain before an ordinary game happens to draw a
-- rare entrance or one of the eleven destination layouts.
function test.run()
    local entries = mod.paths("vaults/ice_cave_entry", ".des")
    local destinations = mod.paths("vaults/ice_cave", ".des")
    local all = {}
    local parsed = {}

    harness.equal(#entries, 15, "source Ice Cave entrances")
    harness.equal(#destinations, 11, "source Ice Cave destinations")

    for _, path in ipairs(entries) do
        parsed[#parsed + 1] = check_entry(path)
        all[#all + 1] = path
    end

    for _, path in ipairs(destinations) do
        check_destination(path)
        all[#all + 1] = path
    end

    harness.equal(map_digest(all), 3975451270,
        "authored Ice Cave MAP corpus")
    harness.equal(eligible_count(parsed, branches.BRANCH_DUNGEON,
        10, 15), 0, "no D:10 gate")
    harness.equal(eligible_count(parsed, branches.BRANCH_DUNGEON,
        11, 15), 7, "D:11 easy gate pool")
    harness.equal(eligible_count(parsed, branches.BRANCH_DUNGEON,
        14, 15), 11, "D:14 hard gate pool")
    harness.equal(eligible_count(parsed, branches.BRANCH_LAIR,
        1, 5), 6, "early Lair easy gate pool")
    harness.equal(eligible_count(parsed, branches.BRANCH_LAIR,
        3, 5), 7, "later Lair easy gate pool")
end

return test
