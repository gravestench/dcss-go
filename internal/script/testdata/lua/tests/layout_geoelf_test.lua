-- Production GeoElf tests exercise source graphs, rendering, metadata, and castle constraints.
local harness = require("tests.harness")
local family = require("policy.generation.layouts.geoelf")
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")
local grid = require("policy.generation.grid")

local test = {}

-- A reproducible stream makes geometry assertions independent of host RNG state.
local function context(seed)
    local state = seed
    local ctx = {}

    -- Use the production layout random contract while varying both halves of each word.
    function ctx:random_u64(stream)
        harness.equal(stream, "layout", "GeoElf random stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return ctx
end

-- A source room graph must form one component with no pair of crossing active corridors.
local function graph_assertions(result)
    local zone = result.room_data[0].zone
    local active = 0

    for index = 0, result.room_data.count - 1 do
        harness.equal(result.room_data[index].zone, zone, "connected GeoElf room graph")
    end

    for index = 0, result.corridor_data.count - 1 do
        local corridor = result.corridor_data[index]

        if corridor.status == 1 then
            active = active + 1

            if corridor.block ~= nil then
                harness.equal(result.corridor_data[corridor.block].status, 2,
                    "crossing corridor blocked")
            end
        end
    end

    harness.truthy(active >= result.room_data.count - 1, "source spanning tree")
end

-- The three free-standing source families retain their graph sizes and usable geometric terrain.
local function ordinary_layout(name, seed, expected_rooms)
    local path = "vaults/layout/" .. name .. ".des"
    local definition = des.parse(path, mod.read(path))
    hooks.validate(definition)

    local module = require("policy.generation.layouts." .. name)
    local result = module[name]({
        ctx = context(seed),
        width = 80,
        height = 70,
        branch = "Elf",
        depth = 2,
        branch_bottom = 3,
        definition = definition,
    })
    local floors = 0

    for y = 0, 69 do
        for x = 0, 79 do
            if result.builder:cell(x, y) == "." then
                floors = floors + 1
            end
        end
    end

    harness.equal(#result.rows, 70, name .. " height")
    harness.truthy(result.room_data.count >= 16, name .. " geometric room count")
    harness.truthy(result.corridor_data.count > result.room_data.count, name .. " potential corridors")
    harness.truthy(floors > 300, name .. " playable area")
    harness.truthy(#result.records > 0, name .. " source terrain records")
    graph_assertions(result)

    if expected_rooms then
        harness.equal(result.room_data.count, expected_rooms, "source ring template count")
    end

    for _, record in ipairs(result.records) do
        if record.kind == "source_feature" then
            harness.truthy(record.base_glyph ~= nil, "source features retain their rendered base")
        elseif record.kind == "monster" then
            harness.truthy(record.arguments.kind_id ~= nil, "plant decoration resolves an actor kind")
        end
    end
end

-- A valid source castle must preserve its preplaced primary and protect the new moat and walls.
local function castle_layout(primary)
    primary = primary or {
        x1 = 30,
        x2 = 49,
        y1 = 25,
        y2 = 39,
    }
    local castle = require("policy.generation.layouts.layout_geoelf_castle")
    harness.truthy(castle.veto({ width = 80, height = 70 }), "castle needs primary vault")
    harness.truthy(castle.veto({
        width = 80,
        height = 70,
        primary_vault = {
            x1 = 30,
            x2 = 31,
            y1 = 30,
            y2 = 31,
        },
    }), "castle rejects tiny primary")

    local ctx = context(891)
    local builder = grid.new(ctx)

    for y = primary.y1, primary.y2 do
        for x = primary.x1, primary.x2 do
            builder:set(x, y, ".")
        end
    end

    builder:set(primary.x1, primary.y1, "+")

    local path = "vaults/layout/layout_geoelf_castle.des"
    local definition = des.parse(path, mod.read(path))
    hooks.validate(definition)

    local api = {
        ctx = ctx,
        builder = builder,
        definition = definition,
        primary_vault = primary,
    }

    harness.equal(castle.veto(api), false, "castle accepts suitable primary")
    local result = castle.layout_geoelf_castle(api)
    harness.equal(result.builder:cell(primary.x1, primary.y1), "+", "primary entrance preserved")
    harness.equal(result.builder:cell(primary.x1 + 1, primary.y1 + 1), ".", "primary interior preserved")
    harness.truthy(#result.spawn_exclusions > 100, "castle non-overwritable footprint")
    harness.truthy(result.castle ~= nil, "source castle design returned")
end

-- Source graph, metadata, and primary-vault contracts run through actual production Lua modules.
function test.run()
    harness.truthy(type(family.new) == "function", "private GeoElf state factory")

    castle_layout()
end

test.ordinary_layout = ordinary_layout
test.castle_layout = castle_layout

return test
