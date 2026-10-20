-- Shop placement preserves protected cells from the source map.

local catalog = require("policy.generation.vaults.catalog")
local extra = require("policy.generation.vaults.extra")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local branches = require("ids.branches")
local categories = require("constants.catalog")
local ids = require("ids.vaults")

local test = {}

-- Keep one policy route under test while the source vault catalog grows.
-- The same exclusion fact is understood by chance, tag, and depth draws.
local function exclude_except(allowed_ids)
    local allowed = {}
    local excluded = {}

    for _, id in ipairs(allowed_ids) do
        allowed[id] = true
    end

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        if not allowed[id] then
            excluded[id] = true
        end
    end

    return excluded
end

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

    local placed = extra.place(nil, builder, catalog.get(ids.shop), {
        protected = protected,
        required = {},
        player = {
            map_tag = ids.shop,
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

    local placed = extra.place(nil, builder, catalog.get(ids.shop), {
        protected = protected,
        required = {},
        player = {
            map_tag = ids.shop,
        },
    })

    harness.truthy(placed, "shop fits another floor cell")
    harness.equal(builder:cell(2, 2), ".",
        "source shop preserved protected cell")
    harness.truthy(protected[placed.entry.x .. ":" .. placed.entry.y],
        "placed shop cell becomes protected")
end

-- Source ordinary minivault selection is independent of the earlier
-- CHANCE controller stage and can place a depth-qualified non-extra map.
local function ordinary_minivault_is_independent_of_serial_chance()
    local builder = floor_builder()

    -- Select the only allowed weighted map and its first legal origin.
    function builder:roll()
        return 0
    end

    local placed, primary = extra.generate(nil, builder, {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 2,
        branch_bottom = 15,
        absolute_depth = 2,
        layout_family = "halls",
        excluded = exclude_except({ ids.serial_bayou_lake_a }),
        protected = {},
        required = {},
        player = {
            branch_id = branches.BRANCH_DUNGEON,
            depth = 2,
            absolute_depth = 2,
            branch_bottom = 15,
        },
    })

    harness.equal(#placed, 1, "ordinary minivault places without serial")
    harness.equal(placed[1].id, primary,
        "weighted minivault owns its source ID")
end

-- The source CHANCE roll selects the DES controller. Its named Lua hook
-- then places a tagged child map and both IDs enter saved vault history.
local function chance_controller_places_tagged_child()
    local builder = floor_builder()
    -- With only the controller and its depthless child eligible, the
    -- later minivault stage adds no unrelated map.
    function builder:roll()
        return 0
    end

    local placed, primary, vault_ids = extra.generate(nil, builder, {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 4,
        branch_bottom = 15,
        absolute_depth = 4,
        layout_family = "halls",
        excluded = exclude_except({ ids.serial_shops, ids.shop }),
        protected = {},
        required = {},
        player = {
            branch_id = branches.BRANCH_DUNGEON,
            depth = 4,
            absolute_depth = 4,
            branch_bottom = 15,
        },
    })

    harness.equal(primary, ids.serial_shops,
        "DES CHANCE map remains the level controller")
    harness.equal(#placed, 1, "controller hook placed one shop child")
    harness.equal(vault_ids[1], ids.serial_shops,
        "empty-map controller is saved before its child")
    harness.equal(vault_ids[2], placed[1].id,
        "child map ID is saved for later uniqueness checks")
end

-- Keep rollback, minivault, and controller checks together because each
-- route places authored terrain through the same geometric operation.
function test.run()
    rejects_protected_shop_cell()
    fits_other_floor()
    ordinary_minivault_is_independent_of_serial_chance()
    chance_controller_places_tagged_child()
end

return test
