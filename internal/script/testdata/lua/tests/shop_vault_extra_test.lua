-- Shop placement preserves protected cells from the source map.

local catalog = require("policy.generation.vaults.catalog")
local extra = require("policy.generation.vaults.extra")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local branches = require("ids.branches")
local chance_units = require("constants.vault_chance")

local test = {}

-- Build an open floor large enough for the real shop vault footprint, making
-- protected-cell failures a placement issue rather than a size issue.
local function floor_builder()
    local builder = grid.new({})

    for y = 1, 68 do
        for x = 1, 78 do
            builder:set(x, y, ".")
        end
    end

    return builder
end

-- A failed shop fit must restore protected terrain instead of leaving a mark.
local function rejects_protected_shop_cell()
    local builder = floor_builder()
    local protected = {
        ["2:2"] = true,
    }

    -- Always select the first candidate, which overlaps the protected cell
    -- and makes rollback of the rejected placement observable.
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

-- Another floor cell may accept the shop after the blocked candidate fails.
local function fits_other_floor()
    local builder = floor_builder()
    local protected = {
        ["2:2"] = true,
    }
    local draw = 0

    -- Vary candidate draws until an unprotected floor fits, proving the
    -- placement loop can recover from an earlier blocked candidate.
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

-- Generic extra map selection and the serial-shop controller have separate
-- eligibility so the same shop vault is not sampled twice.
local function generic_extra_is_independent_of_serial_chance()
    local builder = floor_builder()

    -- Reject the serial-shop chance draw while selecting the generic extra,
    -- so the test can distinguish the two generation routes.
    function builder:roll(bound)
        if bound == chance_units.ROLL then
            return chance_units.ROLL - 1
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

-- Keep the rollback, retry, and generic-extra cases together because all
-- three protect authored shop terrain from duplicate or invalid placement.
function test.run()
    rejects_protected_shop_cell()
    fits_other_floor()
    generic_extra_is_independent_of_serial_chance()
end

return test
