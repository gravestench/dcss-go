-- Vaults uses eleven source primary layouts, not a Dungeon layout renamed
-- for the branch. Their DES metadata selects distinct Lua carving hooks.
local branches = require("ids.branches")
local glyphs = require("constants.vault_glyphs")
local tags = require("constants.vault_tags")
local catalog = require("policy.generation.layouts.catalog")
local graph = require("policy.generation.layouts.cell_graph")
local geometry = require("policy.generation.layouts.vaults.geometry")
local harness = require("tests.harness")
local vaults = require("policy.generation.vaults.catalog")
local weights = require("policy.generation.vaults.weight")

local test = {}

local passable = {
    ["."] = true,
    ["+"] = true,
    ["~"] = true,
    ["="] = true,
    ["W"] = true,
}

for glyph in pairs(glyphs.up) do
    passable[glyph] = true
end

for glyph in pairs(glyphs.down) do
    passable[glyph] = true
end

local source_layouts = {
    {
        id = "layout_vaults_big_cross",
        weight = 10,
    },
    {
        id = "layout_vaults_big_room",
        weight = 20,
    },
    {
        id = "layout_vaults_chaotic_city",
        weight = 20,
    },
    {
        id = "layout_vaults_maze",
        weight = 10,
    },
    {
        id = "layout_vaults_maze_bifur",
        weight = 10,
    },
    {
        id = "layout_vaults_maze_snakey",
        weight = 10,
    },
    {
        id = "layout_vaults_omnibox",
        weight = 30,
    },
    {
        id = "layout_vaults_omnicross",
        weight = 30,
    },
    {
        id = "layout_vaults_omnigrid",
        weight = 50,
    },
    {
        id = "layout_vaults_quadrants",
        weight = 20,
    },
    {
        id = "layout_vaults_ring",
        weight = 25,
    },
}

-- Use the production layout stream contract while making every shape
-- reproducible independently of file discovery and unrelated tests.
local function context_for(seed)
    local state = seed
    local context = {}

    -- Mirror the engine's two-word draw shape without borrowing mutable
    -- state from another Lua test or hard-coding one map's random sequence.
    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    -- Keep the bounded draw contract used by layout and DES room selection.
    function context:random(_, bound)
        state = (state * 48271) % 2147483647

        return state % bound
    end

    return context
end

-- All source motifs need walkable cells, a connected stair region, and
-- authored rooms. A painted motif alone is not a populated Vaults level.
function test.run()
    local wall_draw = {
        value = 0,
    }

    -- Pin source wall-material boundaries without copying the geometry
    -- algorithm: shallow Vaults is stone, deep Vaults can be metal or crystal.
    function wall_draw:roll(bound)
        return math.min(self.value, bound - 1)
    end

    harness.equal(geometry.wall(wall_draw, 1), "c",
        "Vaults:1 uses source stone walls")
    harness.equal(geometry.wall(wall_draw, 4), "v",
        "Vaults:4 commonly uses metal walls")
    wall_draw.value = 999
    harness.equal(geometry.wall(wall_draw, 4), "b",
        "Vaults:4 retains rare crystal walls")

    local count = 0

    for index, expected in ipairs(source_layouts) do
        local id = expected.id
        local definition = catalog.get(id)

        harness.equal(weights.for_branch(definition,
            branches.BRANCH_VAULTS, 1, 5), expected.weight,
            id .. " retains its source weight")
        harness.truthy(definition.tags.layout_type_vaults,
            id .. " retains its Vaults layout family")

        local result = catalog.execute(context_for(1000 + index),
            definition, branches.BRANCH_VAULTS, 1)
        local floor = 0

        for _, row in ipairs(result.rows) do
            for glyph in row:gmatch(".") do
                if glyph == "." then
                    floor = floor + 1
                end
            end
        end

        harness.equal(result.id, id, "source layout ID survives generation")
        harness.truthy(floor > 20, id .. " makes a playable floor")
        harness.truthy(#result.stairs >= 3, id .. " has connected stairs")
        local regions = graph.regions(result.builder, passable)
        local main = {}
        local disconnected = {}

        for _, point in ipairs(regions[1]) do
            main[point.x .. ":" .. point.y] = true
        end

        for _, point in ipairs(result.room_entries) do
            local position = point.x .. ":" .. point.y

            if not main[position] then
                disconnected[#disconnected + 1] = position
            end
        end

        for _, pair in ipairs(result.stairs) do
            local endpoints = { pair.up, pair.down }

            for endpoint_index = 1, 2 do
                local point = endpoints[endpoint_index]

                if point then
                    local position = point.x .. ":" .. point.y

                    if not main[position] then
                        disconnected[#disconnected + 1] = position
                    end
                end
            end
        end

        harness.truthy(#result.room_entries > 0,
            id .. " inserted chambers with reachable entry points")
        harness.equal(#disconnected, 0,
            id .. " keeps room entries and stairs connected; isolated " ..
            table.concat(disconnected, ","))
        harness.truthy(#result.room_ids > 0,
            id .. " places authored source rooms")

        for _, room_id in ipairs(result.room_ids) do
            local room = vaults.get(room_id)

            harness.truthy(room.tags[tags.VAULTS_ROOM] or
                room.tags[tags.VAULTS_EMPTY] or
                room.tags[tags.VAULTS_HARD] or
                room.tags[tags.VAULTS_WIZLAB] or
                room.tags[tags.VAULTS_DESOLATION],
                room_id .. " comes from a Vaults room pool or special portal")
        end

        count = count + 1
    end

    harness.equal(count, 11, "all source primary Vaults layouts run")
end

return test
