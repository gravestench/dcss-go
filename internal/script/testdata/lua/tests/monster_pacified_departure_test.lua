-- Pacified routing reads the same AI component and grid methods as the
-- live game. This sparse fixture only chooses whether its one stair has
-- a route; the Go game test verifies the real pathfinder and save bridge.
local behaviors = require("constants.ai_behaviors")
local component = require("constants.component")
local departure = require("policy.ai.pacified_departure")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local intents = require("constants.intent")
local monsters = require("ids.monsters")
local terrain = require("constants.terrain")

local test = {}

-- Give the policy a bounded floor with one source stair. The route flag
-- stands for the generic grid service's reachability result, not a
-- second pathfinding implementation in this test.
local function floor(ctx)
    local game = fixture.observed_context(ctx)
    local monster = fixture.actor(ctx, monsters.MONS_ORC,
        3, 2, 10)

    game.cells["5:2"] = terrain.DNGN_STONE_STAIRS_DOWN_I
    game.route_open = true
    game:add(monster, component.AI, {
        behavior = behaviors.WANDER,
    })

    -- Match the sparse floor's dimensions for the policy's exit scan.
    function game:level_size()
        return 8, 5
    end

    -- The committed terrain ID is the fixture's only exit feature.
    function game:travel_feature_at(_, x, y)
        return self.cells[x .. ":" .. y] ==
            terrain.DNGN_STONE_STAIRS_DOWN_I
    end

    -- Toggle generic reachability without reimplementing Go pathfinding.
    function game:route_step(_, from_x, _, to_x)
        if not self.route_open or to_x ~= 5 then
            return 0, 0, false
        end

        return to_x > from_x and 1 or -1, 0, true
    end

    return game, monster
end

-- A reachable stair becomes the saved AI target and produces the ordinary
-- move intent, so movement and collision remain generic engine concerns.
local function reachable(ctx)
    local game, monster = floor(ctx)
    local state = game:get(monster, component.AI)
    local position = game:get(monster, component.POSITION)
    local next_state, intent = departure.intent(game,
        monster, state, position)

    harness.equal(next_state.target_x, 5)
    harness.equal(next_state.target_y, 2)
    harness.equal(intent.kind, intents.MOVE)
end

-- Once the grid reports no route, the owner clears its old destination
-- and yields to ordinary neutral wandering instead of waiting forever.
local function blocked(ctx)
    local game, monster = floor(ctx)
    local state = game:get(monster, component.AI)
    local position = game:get(monster, component.POSITION)

    state.target_x = 5
    state.target_y = 2
    game.route_open = false

    local next_state, intent = departure.intent(game,
        monster, state, position)

    harness.equal(next_state, nil)
    harness.equal(intent, nil)
    harness.equal(state.target_x, 0)
    harness.equal(state.target_y, 0)
end

-- Separate fixture wrappers keep each route flag independent while using
-- the harness's real ECS components and production monster IDs.
function test.run(ctx)
    reachable(ctx)
    blocked(ctx)
end

return test
