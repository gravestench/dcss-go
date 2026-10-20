-- The window serial combines three source map pools and an optional glass pool.
local categories = require("constants.catalog")
local catalog = require("policy.generation.vaults.catalog")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local ids = require("ids.vaults")
local placement = require("policy.generation.vaults.placement")
local tags = require("constants.vault_tags")
local branches = require("ids.branches")

local test = {}

-- The source controller chooses independent counts for the small, common,
-- rare, and glass pools. The last pool can be empty until its maps arrive.
local function controller_contract()
    local vault = catalog.get(ids.serial_co_window_serial)
    local requested = {}
    local api = {}

    -- Highest draws exercise every pool and the full count expressions.
    function api:roll(bound)
        return bound - 1
    end

    function api:place_maps(tag, count)
        requested[#requested + 1] = {
            tag = tag,
            count = count,
        }
    end

    hooks.run(vault, "place_co_window_serial", api)

    harness.equal(#vault.rows, 0, "window controller has no MAP cells")
    harness.equal(#requested, 4, "four source map pool requests")
    harness.equal(requested[1].tag, tags.SERIAL_CO_WINDOW_SMALL,
        "small map pool")
    harness.equal(requested[1].count, 9, "small map count")
    harness.equal(requested[2].tag, tags.SERIAL_CO_WINDOW_COMMON,
        "common map pool")
    harness.equal(requested[2].count, 7, "common map count")
    harness.equal(requested[3].tag, tags.SERIAL_CO_WINDOW_RARE,
        "rare map pool")
    harness.equal(requested[3].count, 2, "rare map count")
    harness.equal(requested[4].tag, tags.SERIAL_GLASS,
        "optional glass map pool")
    harness.equal(requested[4].count, 5, "glass map count")
end

-- Each of the 28 authored pieces must parse and fit a normal Dungeon grid.
-- Their pool tags, rather than their file order, control the serial blend.
local function every_piece_places()
    local counts = {
        [tags.SERIAL_CO_WINDOW_SMALL] = 0,
        [tags.SERIAL_CO_WINDOW_COMMON] = 0,
        [tags.SERIAL_CO_WINDOW_RARE] = 0,
    }

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        for tag in pairs(counts) do
            if definition.tags[tag] then
                counts[tag] = counts[tag] + 1

                local builder = grid.new({})

                function builder:roll()
                    return 0
                end

                local vault = catalog.get(id)
                local placed = placement.place(nil, builder, vault, {
                        branch_id = branches.BRANCH_DUNGEON,
                        depth = 1,
                        branch_bottom = 15,
                        layout_family = "open",
                    })

                harness.truthy(placed, "window piece places " .. id)
                harness.truthy(#vault.rows > 0,
                    "window piece has MAP rows " .. id)
            end
        end
    end

    harness.equal(counts[tags.SERIAL_CO_WINDOW_SMALL], 5,
        "complete small source pool")
    harness.equal(counts[tags.SERIAL_CO_WINDOW_COMMON], 18,
        "complete common source pool")
    harness.equal(counts[tags.SERIAL_CO_WINDOW_RARE], 5,
        "complete rare source pool")
end

-- Check the controller and the entire named family together.
function test.run()
    controller_contract()
    every_piece_places()
end

return test
