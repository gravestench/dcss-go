-- Xom's stair tests use one small grid proxy, but exercise the production
-- effect, selector, command, and saved component schema directly.
local bad = require("policy.religion.xom.selection_bad")
local component = require("constants.component")
local events = require("ids.xom_events")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local navigation = require("policy.commands.navigation")
local repel = require("policy.religion.xom.stair_repel")
local species = require("ids.species")
local stairs = require("policy.religion.xom.effects.stairs")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local test = {}

-- The proxy exposes a single movable stair. Its coordinates change after
-- each action, so later checks observe the same grid state as the effect.
-- The Game test separately proves the real Go travel link moves with it.
local function stair_fixture(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)
    local site = {
        x = 9,
        y = 7,
    }

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    -- Keep the sparse floor bounded so rays cannot walk forever.
    function owner:cell(_, x, y)
        if x < 1 or x > 14 or y < 1 or y > 13 then
            return nil
        end

        if x == site.x and y == site.y then
            return terrain.DNGN_STONE_STAIRS_DOWN_I
        end

        return terrain.DNGN_FLOOR
    end

    -- A single visible stair is enough to exercise Xom's eligibility.
    function owner:visible_cells()
        return {
            {
                x = site.x,
                y = site.y,
            },
        }
    end

    -- The focused proxy reports the moved link at its current coordinate.
    function owner:stair_at(_, x, y)
        if x == site.x and y == site.y then
            return {
                to_level_id = 2,
            }
        end
    end

    -- The test stair is also a directional travel feature. Production
    -- checks this terrain property even without an outgoing link.
    function owner:travel_feature_at(_, x, y)
        return x == site.x and y == site.y
    end

    -- Changing the proxy's coordinate models the live grid transaction.
    function owner:move_stair(_, from_x, from_y, to_x, to_y)
        harness.equal(from_x, site.x)
        harness.equal(from_y, site.y)
        site.x = to_x
        site.y = to_y
    end

    -- Low draws make movement and climb repulsion deterministic here.
    function owner:random()
        return 0
    end

    return owner, player, site
end

-- The movement-only event refreshes its timer without erasing an active
-- climb timer. A climb attempt then moves the stair beneath the player.
local function live_effect(ctx, owner, player, site)
    local moved = stairs.apply(owner, player,
        events.BAD_MOVING_STAIRS, 20)
    local status = ctx:get(player, component.XOM_STAIR_REPEL)

    harness.equal(moved, 1)
    harness.truthy(site.x > 9)
    harness.equal(status.move_aut, 1000)
    harness.equal(status.climb_aut, 0)

    repel.tick(ctx, player, 10)
    harness.equal(ctx:get(player,
        component.XOM_STAIR_REPEL).move_aut, 990)

    stairs.apply(owner, player, events.BAD_CLIMB_STAIRS, 20)

    local climb = ctx:get(player, component.XOM_STAIR_REPEL)
    local before_climb = site.x

    harness.equal(climb.move_aut, 1000)
    harness.equal(climb.climb_aut, 500)

    stairs.apply(owner, player, events.BAD_MOVING_STAIRS, 20)

    local refreshed = ctx:get(player, component.XOM_STAIR_REPEL)

    harness.equal(refreshed.move_aut, 1000)
    harness.equal(refreshed.climb_aut, 500)

    ctx:set(player, component.POSITION, {
        level_id = 1,
        x = site.x,
        y = site.y,
    })

    harness.truthy(repel.attempt_climb(owner, player, {
        level_id = 1,
        x = site.x,
        y = site.y,
    }))
    harness.truthy(site.x ~= before_climb)
end

-- Fixed bounds pin the source's short-circuit RNG order without requiring
-- every test case to repeat a large anonymous random override.
local function fixed_draws(owner, bounds, values)
    local index = 0

    -- A missing or extra draw fails at its own bound rather than changing
    -- a later action selection in a way that is hard to diagnose.
    function owner:random(stream, bound)
        index = index + 1
        harness.equal(stream, streams.RELIGION)
        harness.equal(bound, bounds[index])

        return values[index] or bound - 1
    end

    return function()
        return index
    end
end

-- The stair chance follows nine prior bad gates, then its one-in-five
-- draw chooses climb repulsion when the visible stair can move.
local function stair_gate(ctx, owner, player)
    ctx:remove(player, component.XOM_STAIR_REPEL)

    local bounds = {}

    for index = 1, 10 do
        bounds[index] = 20
    end

    bounds[11] = 5

    local used = fixed_draws(owner, bounds, {
        [10] = 0,
        [11] = 0,
    })
    local state = {
        god_id = gods.XOM,
        gift_timeout = 10,
    }

    harness.equal(bad.choose(owner, player, state, 20, 2,
        streams.RELIGION), events.BAD_CLIMB_STAIRS)
    harness.equal(used(), 11)

    return state
end

-- An up command on a down stair is rejected freely. Repulsion may only
-- intercept a command that actually uses the matching stair direction.
local function wrong_direction(ctx, owner, player, site)
    repel.start(ctx, player, true)

    function owner:random()
        return 0
    end

    ctx:set(player, component.POSITION, {
        level_id = 1,
        x = site.x,
        y = site.y,
    })

    local before = site.x
    local rejected = navigation.stairs(owner, {
        level_id = 1,
        x = site.x,
        y = site.y,
    }, false)

    harness.equal(rejected.message, "There are no stairs up here.")
    harness.equal(site.x, before)
end

-- An active timer suppresses another stair event. Mutation and hostile
-- summons remain the next eligible bad actions in source priority.
local function tail_gates(owner, player, state)
    local bounds = {}

    for index = 1, 10 do
        bounds[index] = 20
    end

    bounds[11] = 2
    bounds[12] = 20

    local mutation_used = fixed_draws(owner, bounds, {
        [10] = 0,
        [11] = 0,
        [12] = 0,
    })

    harness.equal(bad.choose(owner, player, state, 20, 2,
        streams.RELIGION), events.BAD_MUTATION)
    harness.equal(mutation_used(), 12)

    bounds[13] = 20

    local summon_used = fixed_draws(owner, bounds, {
        [10] = 0,
        [11] = 0,
        [13] = 0,
    })

    harness.equal(bad.choose(owner, player, state, 20, 2,
        streams.RELIGION), events.BAD_SUMMON_HOSTILES)
    harness.equal(summon_used(), 13)
end

-- Run each named behavior against one shared stair to cover its sequence.
function test.run(ctx)
    local owner, player, site = stair_fixture(ctx)

    live_effect(ctx, owner, player, site)

    local state = stair_gate(ctx, owner, player)

    wrong_direction(ctx, owner, player, site)
    tail_gates(owner, player, state)
end

return test
