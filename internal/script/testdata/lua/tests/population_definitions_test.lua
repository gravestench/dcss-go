-- Population records own branch weights; monster profiles own actor traits.
-- This separation lets a mod add an ambient row without replacing a monster.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local pool = require("policy.population.pool")
local roster = require("policy.population.roster")
local validation = require("content.validation")

local test = {}
local generated = "generated-dungeon-basic-v1"
local fixed = "fixed-dungeon-population-v1"

-- The source Dungeon table has one branch-owned record with 125 rows.
-- The rat profile should no longer duplicate any of those weights.
local function source_rows_have_one_owner()
    local dungeon = register.get(categories.POPULATIONS,
        branches.BRANCH_DUNGEON)
    local rat = register.get(categories.MONSTERS, monsters.MONS_RAT)

    harness.equal(#dungeon.rows, 125, "Dungeon source row count")
    harness.falsy(rat.population, "monster profile repeats branch rows")

    local allowed = roster.allowed(generated, branches.BRANCH_DUNGEON)
    local first, first_total = pool.at_depth(branches.BRANCH_DUNGEON,
        1, allowed, generated)
    local second, second_total = pool.at_depth(branches.BRANCH_DUNGEON,
        2, allowed, generated)

    harness.truthy(#first > 10 and first_total > 0,
        "D:1 has source monsters")
    harness.truthy(#second > 12 and second_total > 0,
        "D:2 has source monsters")

    for depth = 1, 15 do
        local rows, total = pool.at_depth(branches.BRANCH_DUNGEON,
            depth, allowed, generated)

        harness.truthy(#rows > 0 and total > 0,
            "Dungeon:" .. depth .. " has no population")
    end
end

-- Fixed benchmarks filter the same branch data through their pinned roster.
-- Their weights must remain exact despite moving the rows into one catalog.
local function fixed_roster_keeps_weights()
    local allowed = roster.allowed(fixed, branches.BRANCH_DUNGEON)
    local first, first_total = pool.at_depth(branches.BRANCH_DUNGEON,
        1, allowed, fixed)
    local second, second_total = pool.at_depth(branches.BRANCH_DUNGEON,
        2, allowed, fixed)

    harness.equal(#first, 5, "fixed D:1 source row count")
    harness.equal(#second, 7, "fixed D:2 source row count")
    harness.equal(first_total, 7156800, "fixed D:1 weight")
    harness.equal(second_total, 10936800, "fixed D:2 weight")
end

-- A malformed row is rejected during content loading with its catalog ID
-- and row number, before a random turn can reach the broken branch.
local function invalid_curve_is_rejected()
    local definition = register.get(categories.POPULATIONS,
        branches.BRANCH_DUNGEON)
    local original_get = register.get

    -- The Go registry returns a decoded value. Intercept the read that
    -- validation performs instead of changing a detached copy.
    register.get = function(category, id)
        if category == categories.POPULATIONS and id == definition.id then
            definition.rows[1].curve = "UNKNOWN_CURVE"

            return definition
        end

        return original_get(category, id)
    end

    local valid, reason = pcall(validation.branch_populations)
    register.get = original_get

    harness.falsy(valid, "unknown curve was accepted")
    harness.truthy(reason:find("unsupported curve", 1, true),
        "curve error does not name the rule")
end

-- A typo in a sparse mod must name the branch row at startup rather than
-- failing after the first player enters that branch.
local function missing_monster_is_rejected()
    local definition = register.get(categories.POPULATIONS,
        branches.BRANCH_DUNGEON)
    local original_get = register.get

    register.get = function(category, id)
        if category == categories.POPULATIONS and id == definition.id then
            definition.rows[1].monster_id = "MONS_NOT_REGISTERED"

            return definition
        end

        return original_get(category, id)
    end

    local valid, reason = pcall(validation.branch_populations)
    register.get = original_get

    harness.falsy(valid, "missing source monster was accepted")
    harness.truthy(reason:find("row 1", 1, true),
        "missing monster diagnostic omits row")
    harness.truthy(reason:find("MONS_NOT_REGISTERED", 1, true),
        "missing monster diagnostic omits ID")
end

-- Each test uses the same effective catalog and picker as production.
function test.run()
    source_rows_have_one_owner()
    fixed_roster_keeps_weights()
    invalid_curve_is_rejected()
    missing_monster_is_rejected()
end

return test
