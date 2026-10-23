-- The source corpus is committed as individual DES files. This test reads
-- the effective VFS that play uses, so a missing or changed MAP fails
-- without requiring the C++ checkout at build time.
local des = require("policy.generation.vaults.des")
local branches = require("ids.branches")
local component = require("constants.component")
local eligibility = require("policy.generation.vaults.eligibility")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local placement = require("policy.generation.vaults.placement")
local portal = require("policy.world.volcano.portal")

local test = {}

-- Each source map receives the same seeded two-word random interface as
-- live vault placement, isolated from file enumeration order.
local function random_context(seed)
    local state = seed
    local context = {}
    context.components = {}

    -- The same clock constructor used by population records its Akara
    -- intent here without duplicating the production component schema.
    function context:create()
        return #self.components + 1
    end

    -- Keep the complete source state so the deadline can be checked.
    function context:add(entity, kind, state)
        self.components[entity] = {
            kind = kind,
            state = state,
        }
    end

    -- Fixed test time proves population does not restart the source draw.
    function context:aut()
        return 123
    end

    -- Supply both words of the production generation RNG draw.
    function context:random_u64()
        state = (state * 1664525 + 1013904223) % 4294967296
        local high = state
        state = (state * 1664525 + 1013904223) % 4294967296

        return high, state
    end

    -- Trap and item rules share the bounded random context with placement.
    function context:random(_, bound)
        state = (state * 1664525 + 1013904223) % 4294967296

        return state % bound
    end

    return context
end

-- Sort by stable NAME, not directory enumeration, before hashing rows.
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

-- The three tagged helper pools cannot enter the weighted whole-floor
-- destination draw; they are requested by their respective parents.
local function is_helper(map)
    return map.tags.volcano_grotto_subvault or
        map.tags.volcano_lake_subvault or
        map.tags.volcano_tomb_subvault
end

-- Resolve all active hooks, keyed entities, and markers on the actual
-- production placement owner before those records reach population.
local function check_placement(map, seed, entry)
    local random = random_context(seed)
    local branch = entry and branches.BRANCH_LAIR or
        branches.BRANCH_VOLCANO
    local depth = 1
    local bottom = entry and 5 or 1
    local placed = placement.place(random, grid.new(random), map, {
        branch_id = branch,
        depth = depth,
        branch_bottom = bottom,
        absolute_depth = 14,
        layout_family = "open",
    })

    harness.truthy(placed and #placed.records > 0,
        map.id .. " did not place typed source records")

    if entry then
        local clocks = 0

        for index, record in ipairs(placed.records) do
            -- The Go stage adds these transport fields before ordinary
            -- population passes the record to this same Lua constructor.
            record.source_id = record.vault_id
            record.index = index

            if portal.is_marker(record) then
                portal.materialize(random, { id = 1 }, record)
                clocks = clocks + 1
            end
        end

        harness.equal(clocks, 1, map.id .. " portal marker count")
        harness.equal(#random.components, 1,
            map.id .. " Akara portal count")

        local saved = random.components[1]
        local state = saved.state

        harness.equal(saved.kind, component.WORLD_VOLCANO_PORTAL,
            map.id .. " portal component")
        harness.truthy(state.duration_turns >= 600 and
            state.duration_turns <= 800,
            map.id .. " source clock draw")
        harness.equal(state.expires_aut,
            123 + state.duration_turns * 10,
            map.id .. " saved deadline")
    end
end

-- Check source identities, selection metadata, and executable hook sites
-- before a seed happens to select one rare portal or destination.
function test.run()
    local entries = mod.paths("vaults/volcano_entry", ".des")
    local destinations = mod.paths("vaults/volcano", ".des")
    local paths = {}
    local helpers = 0
    local top_level = 0

    harness.equal(#entries, 11, "source Volcano entrances")
    harness.equal(#destinations, 23, "source Volcano destinations")

    for index, path in ipairs(entries) do
        local map = des.parse(path, mod.read(path))

        harness.truthy(map.tags.uniq_volcano and
            map.tags.chance_volcano,
            map.id .. " lacks source portal tags")
        harness.equal(map.chances[1].chance, 500,
            map.id .. " source chance")
        harness.truthy(eligibility.depth(map, {
            branch_id = branches.BRANCH_LAIR,
            depth = 1,
            branch_bottom = 5,
            absolute_depth = 14,
        }), map.id .. " cannot spawn in Lair")
        hooks.validate(map)
        check_placement(map, index, true)
        paths[#paths + 1] = path
    end

    for index, path in ipairs(destinations) do
        local map = des.parse(path, mod.read(path))

        if is_helper(map) then
            helpers = helpers + 1
        else
            top_level = top_level + 1
            harness.equal(map.orientation, "encompass",
                map.id .. " whole-floor orientation")
        end

        hooks.validate(map)

        if is_helper(map) then
            check_placement(map, index + 100, false)
        end

        paths[#paths + 1] = path
    end

    harness.equal(helpers, 9, "tagged Volcano helpers")
    harness.equal(top_level, 14, "weighted Volcano floors")
    harness.equal(map_digest(paths), 1994135705,
        "authored Volcano MAP corpus")
end

return test
