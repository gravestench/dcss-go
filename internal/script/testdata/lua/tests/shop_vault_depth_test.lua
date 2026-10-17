local branches = require("ids.branches")
local catalog = require("policy.generation.vaults.catalog")
local depth = require("policy.generation.vaults.depth")
local selection = require("policy.generation.vaults.selection")
local harness = require("tests.harness")

local test = {}

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

local function source_chance_rows()
    local serial = catalog.get("serial_shops")

    harness.equal(depth.chance(serial, branches.BRANCH_DUNGEON), 15,
        "Dungeon serial chance")
    harness.equal(depth.chance(serial, branches.BRANCH_DEPTHS), 20,
        "Depths serial chance")
    harness.equal(depth.chance(catalog.get("shop"), branches.BRANCH_DUNGEON),
        100, "ordinary shop has no chance directive")
end

local function weighted_shop_choice()
    local random = {}

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

function test.run()
    branch_ranges_and_exclusions()
    source_chance_rows()
    weighted_shop_choice()
end

return test
