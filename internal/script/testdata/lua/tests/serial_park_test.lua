-- The park controller, eleven pieces, and eight nested helpers form one family.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local catalog = require("policy.generation.vaults.catalog")
local effects = require("constants.vault_effects")
local extra = require("policy.generation.vaults.extra")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local ids = require("ids.vaults")
local tags = require("constants.vault_tags")
local depth = require("policy.generation.vaults.depth")
local eligibility = require("policy.generation.vaults.eligibility")

local test = {}

-- Ask the real controller for its tag and maximum count, then count the
-- registered source maps instead of duplicating a hand-written ID list.
local function controller_contract()
    local vault = catalog.get(ids.serial_park)
    local requested
    local api = {}

    function api:roll(bound)
        return bound - 1
    end

    function api:place_maps(tag, count)
        requested = {
            tag = tag,
            count = count,
        }
    end

    hooks.run(vault, "place_park", api)

    harness.equal(#vault.rows, 0, "park controller has no MAP")
    harness.truthy(eligibility.layout(vault, "open"),
        "source open layout admits the park")
    harness.falsy(eligibility.layout(vault, "halls"),
        "unrelated halls layout excludes the park")
    harness.equal(requested.tag, tags.SERIAL_PARK,
        "source park child tag")
    harness.equal(requested.count, 7, "source maximum child count")

    local pieces = 0
    local helpers = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.tags[tags.SERIAL_PARK] then
            pieces = pieces + 1
        end

        if definition.tags[tags.SERIAL_PARK_MINIVAULT] then
            helpers = helpers + 1
        end
    end

    harness.equal(pieces, 11, "all park pieces are registered")
    harness.equal(helpers, 8, "all nested helpers are registered")
end

-- A last-point weighted draw should choose helper eight. The square map
-- has no native monster declaration; a bush record therefore proves the
-- nested selector reached that helper instead of always taking helper one.
local function weighted_subvault_reaches_last_helper()
    local builder = grid.new({})

    for y = 1, 68 do
        for x = 1, 78 do
            builder:set(x, y, ".")
        end
    end

    function builder:roll(bound)
        return bound == 80 and bound - 1 or 0
    end

    local placed = extra.place(nil, builder,
        catalog.get(ids.serial_park_square3), {
            branch_id = branches.BRANCH_DUNGEON,
            depth = 4,
            branch_bottom = 15,
            protected = {},
            required = {},
            player = {
                branch_id = branches.BRANCH_DUNGEON,
                depth = 4,
                branch_bottom = 15,
            },
        })

    harness.truthy(placed, "nested park square fits")

    local bushes = 0

    for _, record in ipairs(placed.records) do
        if record.kind == effects.MONSTER and
            record.identity == "bush" then
            bushes = bushes + 1
        end
    end

    harness.truthy(bushes > 0,
        "weighted SUBVAULT can choose the final bush helper")
end

-- Select the same nested garden at each parent orientation. The source
-- exclusions are recorded before rotation and projected afterward.
local function rotated_park_path(turns)
    local builder = grid.new({})

    for y = 1, 68 do
        for x = 1, 78 do
            builder:set(x, y, ".")
        end
    end

    -- Eight equal-weight helpers make a roll of 50 select helper six.
    function builder:roll(bound)
        if bound == 80 then
            return 50
        elseif bound == 4 then
            return turns
        end

        return 0
    end

    return extra.place(nil, builder,
        catalog.get(ids.serial_park_paths), {
            branch_id = branches.BRANCH_DUNGEON,
            depth = 4,
            branch_bottom = 15,
            layout_family = "open",
            protected = {},
            required = {},
            player = {
                branch_id = branches.BRANCH_DUNGEON,
                depth = 4,
                branch_bottom = 15,
                layout_family = "open",
            },
        })
end

-- The sixth nested helper also uses glyph 1. Its fungus owns those cells;
-- the earlier parent bush declaration cannot claim them after rotation.
local function helper_monsters_own_their_cells()
    for turns = 0, 3 do
        local placed = rotated_park_path(turns)
        local actors = {}
        local fungi = 0

        harness.truthy(placed, "rotated park path fits")

        for _, record in ipairs(placed.records) do
            if record.kind == effects.MONSTER then
                local cell = record.x .. ":" .. record.y

                harness.falsy(actors[cell],
                    "nested helper and parent both claimed " .. cell)
                actors[cell] = true

                if record.identity == "fungus" then
                    fungi = fungi + 1
                end
            end
        end

        harness.truthy(fungi > 0, "sixth park helper placed fungi")
    end
end

-- Every active child should pass the shared geometric placement path on
-- an open Dungeon floor. This also exercises both nested H and J helper
-- regions and the large authored centerpiece, not just catalog parsing.
local function every_piece_places()
    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.tags[tags.SERIAL_PARK] then
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
                depth = 4,
                branch_bottom = 15,
                layout_family = "open",
                protected = {},
                required = {},
                player = {
                    branch_id = branches.BRANCH_DUNGEON,
                    depth = 4,
                    branch_bottom = 15,
                    layout_family = "open",
                },
            })

            harness.truthy(placed, "park piece fits " .. id)
            harness.truthy(#placed.occupied > 0,
                "park piece projects terrain " .. id)
            harness.truthy(depth.eligible(definition,
                branches.BRANCH_DUNGEON, 4, 15),
                "source default depth admits Dungeon " .. id)
            harness.falsy(depth.eligible(definition,
                branches.BRANCH_ZOT, 4, 5),
                "source default depth excludes Zot " .. id)
        end
    end
end

-- One controller must discover the whole family, and nested maps must
-- use the same weighted catalog path as other tagged source selections.
function test.run()
    controller_contract()
    weighted_subvault_reaches_last_helper()
    helper_monsters_own_their_cells()
    every_piece_places()
end

return test
