-- The source subway controller places three linked station maps as one family.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local effects = require("constants.vault_effects")
local catalog = require("policy.generation.vaults.catalog")
local extra = require("policy.generation.vaults.extra")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local ids = require("ids.vaults")

local test = {}

-- A marker name is a source station identity. Count records after real
-- placement so the test catches maps that parse but lose their links.
local function station_marker_count(id)
    local builder = grid.new({})

    for y = 1, 68 do
        for x = 1, 78 do
            builder:set(x, y, ".")
        end
    end

    function builder:roll()
        return 0
    end

    local placed = extra.place(nil, builder, catalog.get(id), {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 8,
        branch_bottom = 15,
        protected = {},
        required = {},
        player = {
            branch_id = branches.BRANCH_DUNGEON,
            depth = 8,
            branch_bottom = 15,
        },
    })

    harness.truthy(placed, "subway station fits " .. id)

    local markers = 0

    for _, record in ipairs(placed.records) do
        if record.kind == effects.MARKER then
            markers = markers + 1
        end
    end

    return markers
end

-- The controller's tag request must match precisely its three committed
-- children, and each child must keep all three transport markers.
function test.run()
    local controller = catalog.get(ids.serial_nicolae_subway)
    local requested_tag
    local requested_count
    local api = {}

    function api:place_maps(tag, count)
        requested_tag = tag
        requested_count = count
    end

    hooks.run(controller, "place_stations", api)

    harness.equal(#controller.rows, 0, "controller has no MAP cells")
    harness.equal(requested_count, 3, "source requests three stations")

    local children = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.tags[requested_tag] then
            children[#children + 1] = id
        end
    end

    harness.equal(#children, 3, "all station maps are registered")

    for _, id in ipairs(children) do
        harness.equal(station_marker_count(id), 3,
            "each station retains its three links: " .. id)
    end
end

return test
