-- Theory of operation: every source Ossuary map is loaded by the same DES
-- catalog that gameplay uses. These checks catch a lost map, changed
-- geometry, or selection-order drift before a rare portal roll hides it.
local branches = require("ids.branches")
local catalog = require("policy.generation.vaults.catalog")
local chance = require("policy.generation.vaults.chance")
local des = require("policy.generation.vaults.des")
local eligibility = require("policy.generation.vaults.eligibility")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local monster = require("policy.generation.vaults.specs.monster")
local terrain = require("constants.terrain")

local test = {}

-- Isolate each map's random stream so a new file cannot change another
-- map's placement result while this corpus test walks the directory.
local function random_context()
    local state = 83
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    -- Trap alternatives use the same bounded service the real generation
    -- context provides. This keeps the source feature path under test.
    function context:random(_, bound)
        state = (state * 48271) % 2147483647

        return state % bound
    end

    return context
end

-- Include every source MAP byte while ignoring file enumeration order.
-- The expected digest was calculated from the pinned upstream ossuary.des.
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

-- Entrance tags must be static, since the selector sees them before a
-- generation hook has run. The source depth excludes D:3 and D:9.
local function check_entry(path)
    local map = des.parse(path, mod.read(path))

    harness.truthy(map.tags.uniq_ossuary and
        map.tags.no_monster_gen and map.tags.chance_ossuary,
        map.id .. " lacks source selection tags")
    harness.equal(chance.group_tag(map), "chance_ossuary",
        map.id .. " chance family")
    harness.truthy(#map.chances > 0,
        map.id .. " lacks source chance 500")

    for depth = 4, 8 do
        harness.truthy(eligibility.depth(map, {
            branch_id = branches.BRANCH_DUNGEON,
            depth = depth,
            branch_bottom = 15,
            absolute_depth = depth,
        }), map.id .. " cannot appear at D:" .. depth)
    end

    for _, depth in ipairs({ 3, 9 }) do
        harness.truthy(not eligibility.depth(map, {
            branch_id = branches.BRANCH_DUNGEON,
            depth = depth,
            branch_bottom = 15,
            absolute_depth = depth,
        }), map.id .. " leaks to D:" .. depth)
    end

    hooks.validate(map)
end

-- Destination IDs, weights, and generated floors must all come from the
-- effective catalog, allowing a sparse mod map to join without a switch.
local function check_destinations(paths)
    local level = require("policy.generation.ossuary.level")
    local candidates = level.candidates({})

    harness.equal(#candidates, 20, "effective Ossuary destinations")

    for index = 2, #candidates do
        harness.truthy(candidates[index - 1].id < candidates[index].id,
            "Ossuary candidates are not in stable ID order")
    end

    for _, path in ipairs(paths) do
        local map = des.parse(path, mod.read(path))

        harness.equal(catalog.get(map.id).weight, map.weight,
            map.id .. " source weight")
        hooks.validate(map)

        local generated = level.generate(random_context(), {
            layout_id = map.id,
        })
        local floor = generated.level
        local arrival = floor.cells[floor.entry_y + 1]

        harness.equal(floor.vault_id, map.id,
            map.id .. " lost selected source identity")
        harness.equal(arrival[floor.entry_x + 1],
            terrain.DNGN_EXIT_OSSUARY,
            map.id .. " lacks its return-portal arrival")

        local exits = 0

        for _, row in ipairs(floor.cells) do
            for _, cell in ipairs(row) do
                if cell == terrain.DNGN_EXIT_OSSUARY then
                    exits = exits + 1
                end
            end
        end

        harness.truthy(exits > 0, map.id .. " lost its return exit")
    end
end

-- A full-corpus check runs independently of whether a normal playthrough
-- happens to roll a temporary Ossuary gate.
function test.run()
    local named = monster.parse(
        "mummy name:bog n_adj col:green", {
            path = "vaults/ossuary/ossuary_zaba_flooded.des",
            line = 1,
            id = "ossuary_zaba_flooded",
        })[1][1]

    harness.equal(named.name, "mummy", "source n_adj keeps species")
    harness.truthy(named.name_adjective,
        "source n_adj names the generated mummy")

    local entries = mod.paths("vaults/ossuary_entry", ".des")
    local destinations = mod.paths("vaults/ossuary", ".des")

    harness.equal(#entries, 14, "source Ossuary entrances")
    harness.equal(#destinations, 20, "source Ossuary destinations")

    local all = {}

    for _, path in ipairs(entries) do
        check_entry(path)
        all[#all + 1] = path
    end

    for _, path in ipairs(destinations) do
        all[#all + 1] = path
    end

    harness.equal(map_digest(all), 3110416243,
        "authored Ossuary MAP corpus")
    check_destinations(destinations)
end

return test
