-- The effective DES catalog must contain every source Bailey entrance,
-- dispatcher, and destination. This catches a missing or altered map before
-- a rare Dungeon gate roll happens to choose it in normal play.
local branches = require("ids.branches")
local des = require("policy.generation.vaults.des")
local eligibility = require("policy.generation.vaults.eligibility")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")

local test = {}

local source_entry_weights = {
    enter_bailey_1 = 1,
    enter_bailey_2 = 10,
    enter_bailey_3 = 10,
    enter_bailey_4 = 5,
    enter_bailey_5 = 10,
    enter_bailey_6 = 3,
    enter_bailey_7 = 3,
    enter_bailey_8 = 3,
    lightli_bailey_entry_fortress = 1,
}

-- The expected digest was calculated once from the pinned source's 25 MAP
-- blocks. Sorting IDs makes file discovery order irrelevant to this check.
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

-- The selector reads entrance metadata before a hook runs. Every entrance
-- must therefore advertise the source family, chance, and depth statically.
local function check_entry(path)
    local map = des.parse(path, mod.read(path))

    harness.truthy(map.tags.uniq_bailey and
        map.tags.chance_bailey,
        map.id .. " lacks source selection tags")
    harness.truthy(#map.chances > 0,
        map.id .. " lacks source chance 1000")
    harness.equal(map.chances[1].chance, 1000,
        map.id .. " source entrance chance")
    harness.equal(map.weight, source_entry_weights[map.id],
        map.id .. " source entrance weight")

    for depth = 7, 10 do
        harness.truthy(eligibility.depth(map, {
            branch_id = branches.BRANCH_DUNGEON,
            depth = depth,
            branch_bottom = 15,
            absolute_depth = depth,
        }), map.id .. " cannot appear at D:" .. depth)
    end

    for _, depth in ipairs({ 6, 11 }) do
        harness.truthy(not eligibility.depth(map, {
            branch_id = branches.BRANCH_DUNGEON,
            depth = depth,
            branch_bottom = 15,
            absolute_depth = depth,
        }), map.id .. " leaks to D:" .. depth)
    end

    hooks.validate(map)
end

-- The dispatcher is a real source definition, but only its post-place hook
-- may select geometry. Axe and polearm layouts form separate tagged pools.
local function check_destinations(paths)
    local axes = 0
    local polearms = 0
    local dispatcher = 0

    for _, path in ipairs(paths) do
        local map = des.parse(path, mod.read(path))

        hooks.validate(map)

        if map.id == "bailey" then
            dispatcher = dispatcher + 1
            harness.equal(#map.rows, 0,
                "Bailey dispatcher must remain mapless")
        elseif map.tags.bailey_axe then
            axes = axes + 1
        elseif map.tags.bailey_polearm then
            polearms = polearms + 1
        else
            error(map.id .. " has no Bailey theme tag")
        end
    end

    harness.equal(dispatcher, 1, "source Bailey dispatcher")
    harness.equal(axes, 6, "source axe layouts")
    harness.equal(polearms, 9, "source polearm layouts")
end

-- A complete source corpus has nine Dungeon entrances, the one controller,
-- and all 15 playable destinations. No runtime source checkout is needed.
function test.run()
    local entries = mod.paths("vaults/bailey_entry", ".des")
    local destinations = mod.paths("vaults/bailey", ".des")

    harness.equal(#entries, 9, "source Bailey entrances")
    harness.equal(#destinations, 16,
        "source Bailey dispatcher and destinations")

    local all = {}

    for _, path in ipairs(entries) do
        check_entry(path)
        all[#all + 1] = path
    end

    for _, path in ipairs(destinations) do
        all[#all + 1] = path
    end

    harness.equal(map_digest(all), 4077562625,
        "authored Bailey MAP corpus")
    check_destinations(destinations)
end

return test
