-- Shop vault selection respects the authored depth tag.

local branches = require("ids.branches")
local catalog = require("policy.generation.vaults.catalog")
local depth = require("policy.generation.vaults.depth")
local selection = require("policy.generation.vaults.selection")
local harness = require("tests.harness")

local test = {}

-- Probe both edges of authored branch ranges so a shop cannot appear one
-- level early or after its specified destination ends.
local function branch_ranges_and_exclusions()
    local small = catalog.get("kennysheep_mini")

    harness.falsy(depth.eligible(small, branches.BRANCH_DUNGEON, 3, 15),
        "shop starts at D:4")
    harness.truthy(depth.eligible(small, branches.BRANCH_DUNGEON, 4, 15),
        "shop includes D:4")
    harness.falsy(depth.eligible(small, branches.BRANCH_DUNGEON, 15, 15),
        "shop excludes the Dungeon bottom")
    harness.truthy(depth.eligible(small, branches.BRANCH_DEPTHS, 2, 4),
        "shop includes middle Depths")
    harness.falsy(depth.eligible(small, branches.BRANCH_DEPTHS, 4, 4),
        "shop excludes the Depths bottom")

    local final = catalog.get("hellmonk_bargain_basement")

    harness.falsy(depth.eligible(final, branches.BRANCH_ZOT, 4, 5),
        "Zot:5 shop excludes Zot:4")
    harness.truthy(depth.eligible(final, branches.BRANCH_ZOT, 5, 5),
        "Zot:5 shop includes Zot:5")
end

-- Compare branch-specific serial chances with source rows to keep shop
-- frequency tied to the branch rather than a global default.
local function source_chance_rows()
    local serial = catalog.get("serial_shops")

    harness.equal(depth.chance(serial, branches.BRANCH_DUNGEON, 4), 1500,
        "Dungeon serial chance")
    harness.equal(depth.chance(serial, branches.BRANCH_DEPTHS, 2), 2000,
        "Depths serial chance")
    harness.equal(depth.chance(catalog.get("shop"),
        branches.BRANCH_DUNGEON, 4), 10000,
        "ordinary shop has no chance directive")
end

-- Select from weighted shop alternatives with a fixed low draw to verify
-- stable source weights without depending on random sampling.
local function weighted_shop_choice()
    local random = {}

    -- Use the first weighted slot and assert that selection never requests
    -- an empty range, which would make production RNG fail.
    function random:roll(bound)
        harness.truthy(bound > 0, "shop choice has a positive bound")

        return 0
    end

    local selected = selection.choose_tag(random, "shop", {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 4,
        branch_bottom = 15,
    })

    harness.truthy(selected.tags.shop, "source shop tag selected")
    harness.truthy(depth.eligible(selected, branches.BRANCH_DUNGEON, 4, 15),
        "selected vault is eligible at D:4")
end

-- Run range, chance, and weighted-choice cases together because each controls
-- a separate gate before a shop vault is eligible for placement.
function test.run()
    branch_ranges_and_exclusions()
    source_chance_rows()
    weighted_shop_choice()
end

return test
