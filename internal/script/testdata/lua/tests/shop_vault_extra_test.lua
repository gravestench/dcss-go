local catalog = require("policy.generation.vaults.catalog")
local extra = require("policy.generation.vaults.extra")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local branches = require("ids.branches")

local test = {}

local function floor_builder()
    local builder = grid.new({})

    for y = 1, 68 do
        for x = 1, 78 do
            builder:set(x, y, ".")
        end
    end

    return builder
end

local function rejects_protected_shop_cell()
    local builder = floor_builder()
    local protected = {
        ["2:2"] = true,
    }

    function builder:roll()
        return 0
    end

    local placed = extra.place(nil, builder, catalog.get("shop"), {
        protected = protected,
        required = {},
        player = {
            map_tag = "shop",
        },
    })

    harness.falsy(placed, "shop cannot replace protected floor")
    harness.equal(builder:cell(2, 2), ".",
        "failed placement restores protected floor")
end

local function fits_other_floor()
    local builder = floor_builder()
    local protected = {
        ["2:2"] = true,
    }
    local draw = 0

    function builder:roll(bound)
        draw = draw + 1

        return draw % bound
    end

    local placed = extra.place(nil, builder, catalog.get("shop"), {
        protected = protected,
        required = {},
        player = {
            map_tag = "shop",
        },
    })

    harness.truthy(placed, "shop fits another floor cell")
    harness.equal(builder:cell(2, 2), ".",
        "source shop preserved protected cell")
    harness.truthy(protected[placed.entry.x .. ":" .. placed.entry.y],
        "placed shop cell becomes protected")
end

local function generic_extra_is_independent_of_serial_chance()
    local builder = floor_builder()

    function builder:roll(bound)
        if bound == 100 then
            return 99
        end

        return 0
    end

    local placed, controller = extra.generate(nil, builder, {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 2,
        branch_bottom = 15,
        absolute_depth = 2,
        protected = {},
        required = {},
        player = {
            branch_id = branches.BRANCH_DUNGEON,
            depth = 2,
            absolute_depth = 2,
            branch_bottom = 15,
        },
    })

    harness.equal(#placed, 1, "generic extra map places without serial")
    harness.equal(placed[1].id, controller,
        "standalone shop map owns its source ID")
    harness.truthy(controller ~= "serial_shops",
        "serial controller stays outside generic pool")
end

function test.run()
    rejects_protected_shop_cell()
    fits_other_floor()
    generic_extra_is_independent_of_serial_chance()
end

return test
