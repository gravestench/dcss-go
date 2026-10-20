-- Source dummy maps balance regular and minivault selection without cells.
local branches = require("ids.branches")
local catalog = require("policy.generation.vaults.catalog")
local categories = require("constants.catalog")
local depth = require("policy.generation.vaults.depth")
local harness = require("tests.harness")
local ids = require("ids.vaults")
local minivault = require("policy.generation.vaults.minivault")
local used = require("policy.generation.vaults.used")

local test = {}

-- Expose only the source minivault dummy and one real map so the test
-- follows their CHANCE order without depending on later content imports.
local function balanced_context()
    local allowed = {
        [ids.primary_mini_dummy] = true,
        [ids.serial_bayou_lake_a] = true,
    }
    local excluded = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        if not allowed[id] then
            excluded[id] = true
        end
    end

    return {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 4,
        branch_bottom = 15,
        absolute_depth = 4,
        excluded = excluded,
        layout_family = "rooms",
        used = used.new({}),
        player = {},
    }
end

-- A naked numeric DEPTH range uses absolute dungeon depth, then the
-- source branch exclusions can veto it on a specific floor.
local function source_dummy_depths_and_chances()
    local mini = catalog.get(ids.primary_mini_dummy)

    harness.truthy(mini.tags.minivault,
        "unoriented source dummy enters minivault pool")
    harness.truthy(depth.eligible(mini,
        branches.BRANCH_DUNGEON, 4, 15, 4),
        "absolute range admits D:4")
    harness.falsy(depth.eligible(mini,
        branches.BRANCH_DEPTHS, 1, 4, 16),
        "specific Depths:1 exclusion vetoes absolute range")
    harness.equal(depth.chance(mini,
        branches.BRANCH_DUNGEON, 4, 15, 4), 5000,
        "Dungeon minivault suppression chance")
    harness.equal(depth.chance(mini,
        branches.BRANCH_VAULTS, 2, 5, 19), 10000,
        "Vaults always suppresses ordinary minivaults")
    harness.falsy(catalog.get(ids.primary_dummy).tags.minivault,
        "explicit float dummy remains regular")
end

-- The dummy's successful chance ends the stage. A failed dummy chance
-- allows one weighted real map without counting the dummy as placed.
local function dummy_roll_blocks_then_allows()
    local context = balanced_context()
    local candidates = minivault.candidates(context)
    local random = {}

    -- Roll zero within the source 5,000-in-10,000 chance.
    function random:roll()
        return 0
    end

    harness.falsy(minivault.choose(random, candidates, context),
        "successful dummy chance suppresses minivault")

    -- Fail the chance, then choose the sole real map by weight.
    function random:roll(bound)
        if bound == 10000 then
            return 5000
        end

        return 0
    end

    harness.equal(minivault.choose(random, candidates, context).id,
        ids.serial_bayou_lake_a,
        "failed dummy chance permits a real map")
end

-- The source family's two relevant paths guard frequency and range rules.
function test.run()
    source_dummy_depths_and_chances()
    dummy_roll_blocks_then_allows()
end

return test
