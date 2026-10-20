-- Source branch monster rows are Lua content. The production catalog and
-- pool must preserve duplicate rows and the source's empty-roll sentinel.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local pool = require("policy.population.pool")
local roster = require("policy.population.roster")

local test = {}

-- The committed source tables have one definition per branch and keep
-- every source row in authored order, even when a monster repeats.
local function check_rows(branch_id, expected_count)
    local definition = register.get(categories.POPULATIONS, branch_id)

    harness.truthy(definition, branch_id .. " population exists")
    harness.equal(#definition.rows, expected_count,
        branch_id .. " source population row count")

    return definition.rows
end

-- The committed export covers all active source table slots, including
-- branches with no ordinary ambient rows. A missing file shifts a seeded
-- branch's choices even when early Dungeon tests still pass.
local function check_catalog_scope()
    local definitions = register.ids(categories.POPULATIONS)
    local rows = 0

    harness.equal(#definitions, 38, "source population branch count")

    for _, id in ipairs(definitions) do
        local definition = register.get(categories.POPULATIONS, id)

        rows = rows + #definition.rows
    end

    harness.equal(rows, 908, "active source population row count")
end

-- A source no-monster row is a weighted result, not a missing catalog
-- definition or a reason to choose an unrelated Dungeon monster.
function test.run()
    check_catalog_scope()
    check_rows(branches.BRANCH_DUNGEON, 125)
    check_rows(branches.BRANCH_ORC, 19)
    check_rows(branches.BRANCH_SWAMP, 44)

    local lair = check_rows(branches.BRANCH_LAIR, 36)

    harness.equal(lair[1].monster_id, "MONS_NO_MONSTER",
        "Lair's first source row is an empty roll")
    harness.equal(lair[1].rarity, 4500,
        "Lair empty-roll rarity")
    harness.equal(lair[2].curve, curves.SEMI,
        "Lair second source curve")
    harness.equal(lair[2].monster_id, monsters.MONS_BLACK_BEAR,
        "Lair second source monster")

    local choices, total = pool.at_depth(branches.BRANCH_LAIR,
        1, nil, "generated-dungeon-basic-v1")

    harness.truthy(total > 0, "Lair has a first-floor pool")
    harness.truthy(#choices > 1, "Lair keeps its source choices")
    harness.equal(choices[1].id, "MONS_NO_MONSTER",
        "Lair empty roll remains weighted")

    local swamp = check_rows(branches.BRANCH_SWAMP, 44)

    harness.equal(swamp[3].monster_id, monsters.MONS_SPRIGGAN_RIDER,
        "Swamp preserves its first rider row")
    harness.equal(swamp[4].monster_id, monsters.MONS_SPRIGGAN_RIDER,
        "Swamp preserves its duplicate rider row")

    local orc, orc_total = pool.at_depth(branches.BRANCH_ORC,
        1, nil, "generated-dungeon-basic-v1")

    harness.equal(orc[1].weight, 967680,
        "Orc empty-roll rarity keeps its source weight")
    harness.truthy(orc_total > orc[1].weight,
        "Orc also admits real monsters")

    local depths = check_rows(branches.BRANCH_DEPTHS, 44)
    local depths_pool = pool.at_depth(branches.BRANCH_DEPTHS,
        1, nil, "generated-dungeon-basic-v1")

    harness.equal(depths[1].min_depth, -3,
        "Depths keeps its out-of-depth source range")
    harness.equal(depths_pool[1].weight, 525000,
        "Depths semi curve uses local branch depth")

    local temple, temple_total = pool.at_depth(branches.BRANCH_TEMPLE,
        1, nil, "generated-dungeon-basic-v1")

    harness.equal(#temple, 0, "Temple has no ambient source rows")
    harness.equal(temple_total, 0, "Temple empty pool adds no weight")

    -- A populated branch must have the same effect coverage as Dungeon.
    -- Startup should reject a source caster whose spells cannot execute.
    for _, branch_id in ipairs({
        branches.BRANCH_ORC,
        branches.BRANCH_LAIR,
        branches.BRANCH_SWAMP,
        branches.BRANCH_DEPTHS,
    }) do
        local allowed = roster.allowed("generated-dungeon-basic-v1",
            branch_id)

        harness.truthy(next(allowed), branch_id .. " has no admitted monsters")
    end
end

return test
