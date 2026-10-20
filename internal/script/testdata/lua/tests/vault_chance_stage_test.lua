-- Chance maps are rolled separately from weighted ordinary extras.
local branches = require("ids.branches")
local catalog = require("policy.generation.vaults.catalog")
local chance = require("policy.generation.vaults.chance")
local chance_units = require("constants.vault_chance")
local categories = require("constants.catalog")
local ids = require("ids.vaults")
local used = require("policy.generation.vaults.used")
local harness = require("tests.harness")

local test = {}

-- Boundary tests isolate the shop declaration without assuming the
-- catalog will stop growing as other serial families are imported.
local function exclude_other_chance_maps()
    local excluded = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if #definition.chances > 0 and id ~= ids.serial_shops then
            excluded[id] = true
        end
    end

    return excluded
end

-- The committed serial shop controller has CHANCE: 15% (D). Its threshold
-- uses source's 10,000-point roll and does not include ordinary shop maps.
local function dungeon_chance_boundary()
    local draws = {}
    local random = {}

    function random:roll(bound)
        draws[#draws + 1] = bound

        return 1499
    end

    local context = {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 4,
        branch_bottom = 15,
        layout_family = "halls",
        excluded = exclude_other_chance_maps(),
        used = used.new({}),
    }
    local selected = chance.select(random, context)

    harness.equal(#selected, 1, "one source chance controller succeeds")
    harness.equal(selected[1].id, ids.serial_shops,
        "selected chance map is serial shops")
    harness.equal(draws[1], chance_units.ROLL,
        "source chance roll scale")

    function random:roll()
        return 1500
    end

    harness.equal(#chance.select(random, context), 0,
        "boundary at 15 percent fails")
end

-- A previously placed luniq controller is unavailable again on this floor.
-- An ineligible branch must not spend a chance draw at all.
local function eligibility_before_roll()
    local random = {}
    local draws = 0

    function random:roll()
        draws = draws + 1

        return 0
    end

    local same_floor = used.new({})
    local excluded = exclude_other_chance_maps()

    same_floor:add(catalog.get(ids.serial_shops))

    harness.equal(#chance.select(random, {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 4,
        branch_bottom = 15,
        layout_family = "halls",
        excluded = excluded,
        used = same_floor,
    }), 0, "same-floor controller is excluded")

    harness.equal(#chance.select(random, {
        branch_id = branches.BRANCH_ZOT,
        depth = 4,
        branch_bottom = 5,
        layout_family = "halls",
        excluded = excluded,
        used = used.new({}),
    }), 0, "Zot is outside the shop controller depth")

    harness.equal(draws, 0, "ineligible maps spend no chance draws")
end

-- A failed chance_* map seeks the matching fallback_* family. A map
-- without a chance family has no such source fallback route.
local function fallback_tag_matches_source_family()
    harness.equal(chance.fallback_tag({
        tags = {
            chance_market = true,
        },
    }), "fallback_market", "matching fallback family")
    harness.falsy(chance.fallback_tag({
        tags = {
            extra = true,
        },
    }), "ordinary maps have no fallback family")
end

-- Keep source-boundary and exclusion checks together because both decide
-- whether the same registered map enters the chance placement stage.
function test.run()
    dungeon_chance_boundary()
    eligibility_before_roll()
    fallback_tag_matches_source_family()
end

return test
