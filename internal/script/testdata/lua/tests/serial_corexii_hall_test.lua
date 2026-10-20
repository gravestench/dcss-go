-- Core Xii's statue halls are one chance controller and ten tagged maps.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local catalog = require("policy.generation.vaults.catalog")
local extra = require("policy.generation.vaults.extra")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local ids = require("ids.vaults")

local test = {}

-- Discover children from their real DES tags. This avoids a second
-- handwritten name list that could drift from the effective catalog.
local function children()
    local found = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.tags[ids.serial_corexii_hall] then
            found[#found + 1] = id
        end
    end

    return found
end

-- The source family is complete only if its controller and ten weighted
-- hall shapes are registered as separate effective DES maps.
local function registered_family()
    local serial = catalog.get(ids.serial_corexii_hall)

    harness.equal(#serial.rows, 0, "hall controller has no MAP cells")
    harness.equal(#children(), 10, "all ten authored hall shapes load")
end

-- The source hook asks for two plus a product of two 0..2 draws, which
-- favors fewer halls without hardcoding a fixed child list in Lua.
local function controller_requests_source_count()
    local requested_tag
    local requested_count
    local api = {}

    -- Give each factor one to make the expected count observable.
    function api:roll()
        return 1
    end

    -- Capture the call from the actual controller module.
    function api:place_maps(tag, count)
        requested_tag = tag
        requested_count = count
    end

    hooks.run(catalog.get(ids.serial_corexii_hall),
        "place_serial_corexii_hall", api)

    harness.equal(requested_tag, ids.serial_corexii_hall,
        "controller requests its own child tag")
    harness.equal(requested_count, 3,
        "source product controls hall count")
end

-- Exercise each hall's authored SUBST and MAP through the production
-- geometric path on a normal open Dungeon floor.
local function each_child_places()
    for _, id in ipairs(children()) do
        local builder = grid.new({})

        for y = 1, 68 do
            for x = 1, 78 do
                builder:set(x, y, ".")
            end
        end

        -- Repeat one legal origin and deterministic substitution choices.
        function builder:roll()
            return 0
        end

        local placed = extra.place(nil, builder, catalog.get(id), {
            branch_id = branches.BRANCH_DUNGEON,
            depth = 4,
            branch_bottom = 15,
            protected = {},
            required = {},
            player = {
                branch_id = branches.BRANCH_DUNGEON,
                depth = 4,
                branch_bottom = 15,
                map_tag = ids.serial_corexii_hall,
            },
        })

        harness.truthy(placed, "hall map fits " .. id)
    end
end

-- Catalog, hook, and placement checks cover the complete source family.
function test.run()
    registered_family()
    controller_requests_source_count()
    each_child_places()
end

return test
