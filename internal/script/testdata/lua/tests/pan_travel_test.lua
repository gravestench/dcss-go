-- Portal planning reads source arch features and saved Pan history. These
-- tests use the production policy and terrain IDs, so the Go handoff cannot
-- invent a separate list of gates or command directions.
local harness = require("tests.harness")
local region = require("policy.generation.pan.region")
local terrain = require("constants.terrain")
local operations = require("constants.pan_travel")
local travel = require("policy.world.pan.travel")

local test = {}

-- Return travel uses a neighboring walkable cell if another actor stands on
-- the original portal. The saved origin itself remains unchanged.
local function context(feature)
    local source = {}

    function source:cell()
        return feature
    end

    function source:level_size()
        return 80, 70
    end

    function source:walkable(_, x, y)
        return x >= 0 and x < 80 and y >= 0 and y < 70
    end

    function source:actor_at(_, x, y)
        return x == 4 and y == 5
    end

    return source
end

local function position(level_id)
    return {
        level_id = level_id,
        x = 4,
        y = 5,
    }
end

-- The source entry is one-way and records the exact portal for later exit.
local function check_entry()
    local plan = travel.prepare(context(terrain.DNGN_ENTER_PANDEMONIUM),
        position(3401), true, nil, {})

    harness.equal(plan.portal.operation, operations.NEW_REGION,
        "Pan entrance requests a new region")
    harness.equal(plan.portal.next_state.regions_seen, 1,
        "first Pan region increments history")
    harness.equal(plan.portal.next_state.return_site.level_id, 3401,
        "Pan origin is the portal floor")
    harness.equal(plan.portal.next_state.active_level_id,
        region.level_id(0), "first Pan region storage ID")
end

-- Transit remembers all previous maps and the current map exactly once;
-- it does not push another return site on the portal stack.
local function check_transit()
    local state = {
        regions_seen = 1,
        vault_ids = { "rand_demon_1" },
        active_level_id = region.level_id(0),
        return_site = {
            level_id = 3401,
            x = 4,
            y = 5,
        },
    }
    local plan = travel.prepare(context(terrain.DNGN_TRANSIT_PANDEMONIUM),
        position(state.active_level_id), false, state, { "mnoleg" })

    harness.equal(plan.portal.operation, operations.NEW_REGION,
        "transit requests a fresh region")
    harness.equal(plan.portal.history.levels_seen, 1,
        "transit uses completed region count")
    harness.equal(plan.portal.history.prior_vault_ids[2], "mnoleg",
        "current Pan map joins saved history")
    harness.equal(plan.portal.next_state.return_site.level_id, 3401,
        "transit keeps original portal")
    harness.equal(plan.portal.next_state.active_level_id,
        region.level_id(1), "transit uses a fresh storage ID")
end

-- Exit chooses a safe nearby landing before the old Pan floor is retired.
local function check_exit()
    local state = {
        regions_seen = 1,
        vault_ids = {},
        active_level_id = region.level_id(0),
        return_site = {
            level_id = 3401,
            x = 4,
            y = 5,
        },
    }
    local plan = travel.prepare(context(terrain.DNGN_EXIT_PANDEMONIUM),
        position(state.active_level_id), false, state, { "mnoleg" })

    harness.equal(plan.portal.operation, operations.RETURN,
        "exit returns to the original floor")
    harness.equal(plan.portal.destination.x, 5,
        "occupied portal lands on the next safe cell")
    harness.equal(plan.portal.next_state.active_level_id, 0,
        "exit clears the active region")
    harness.equal(plan.portal.next_state.vault_ids[1], "mnoleg",
        "exited map remains in uniqueness history")
end

-- The Abyss gate is a downward portal that retains the saved Dungeon
-- origin for the eventual escape from the Abyss.
local function check_abyss()
    local state = {
        regions_seen = 1,
        vault_ids = {},
        active_level_id = region.level_id(0),
        return_site = {
            level_id = 3401,
            x = 4,
            y = 5,
        },
    }
    local plan = travel.prepare(context(terrain.DNGN_EXIT_THROUGH_ABYSS),
        position(state.active_level_id), true, state, {})

    harness.equal(plan.portal.operation, operations.ABYSS,
        "Abyss gate leaves Pan through the Abyss")
    harness.equal(plan.portal.return_site.level_id, 3401,
        "Abyss escape keeps the original portal site")
end

function test.run()
    check_entry()
    check_transit()
    check_exit()
    check_abyss()
end

return test
