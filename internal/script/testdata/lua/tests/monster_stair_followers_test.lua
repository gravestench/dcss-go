-- Ordinary stairs tag nearby source-eligible monsters before their next
-- decision, then carry the marked ECS actors across the linked floor.
local action = require("policy.command_action_start")
local behaviors = require("constants.ai_behaviors")
local attitudes = require("constants.attitude")
local component = require("constants.component")
local twin_causes = require("constants.elven_twin")
local branches = require("ids.branches")
local fixture = require("tests.monster_ally_support_fixture")
local followers = require("policy.world.stair_followers")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local decision = require("systems.monster_decision")
local terrain = require("constants.terrain")

local test = {}

-- The sparse fixture still uses the production actor components and
-- action-start policy. Only grid reads are supplied by this test floor.
local function stair_context(ctx)
    local game = fixture.observed_context(ctx)
    local actor_at = game.actor_at

    -- The shared sparse fixture only enumerates ACTOR components, while
    -- the full grid also treats the player as an occupied arrival cell.
    function game:actor_at(level_id, x, y)
        local player = self:player()
        local position = self:get(player, component.POSITION)

        if position.level_id == level_id and
            position.x == x and position.y == y then
            return player
        end

        return actor_at(self, level_id, x, y)
    end

    -- Only the player's fixture cell is a real linked stone stair.
    function game:cell(_, x, y)
        if x == 7 and y == 7 then
            return terrain.DNGN_STONE_STAIRS_DOWN_I
        end

        return terrain.DNGN_FLOOR
    end

    -- The link must be present to admit an accepted stair follower wave.
    function game:stair_at()
        return {
            to_level_id = 2,
            to_x = 7,
            to_y = 7,
            unavailable = "",
        }
    end

    -- Leave enough floor around the stair to exercise the five-cell chain.
    function game:level_size()
        return 20, 20
    end

    return game
end

-- Each candidate gets the same real ECS clock and seek target the source
-- uses at tag time; caller may replace its allegiance or status afterward.
local function candidate(ctx, kind_id, x, y, points)
    local entity = fixture.actor(ctx, kind_id, x, y, 10)

    ctx:add(entity, component.AI, {
        behavior = behaviors.SEEK,
        target_x = 7,
        target_y = 7,
        memory_until_aut = 250,
        bat_retreat_actions = 0,
    })
    ctx:add(entity, component.MONSTER_ENERGY, {
        points = points or 70,
    })

    return entity
end

-- A permanent Beogh gift is a real friendly actor, unlike a summoned
-- ally which the source does not carry through ordinary stairs.
local function friendly(ctx, entity)
    ctx:add(entity, component.BEOGH_ORC, {
        attitude = attitudes.FRIENDLY,
        attempted = true,
        gift = true,
        gift_category = "",
    })
end

-- The command-start policy is the real accepted-action boundary. A
-- pursuing rat standing beside the stair must be marked before it acts.
local function accepted_stair_tags_pursuer(ctx)
    local game = stair_context(ctx)
    local player = game:player()
    local rat = candidate(ctx, monsters.MONS_RAT, 8, 7)

    action.run(game, {
        stair_travel = true,
    })

    harness.truthy(game:has(rat, component.MONSTER_STAIR_FOLLOWER),
        "accepted stair did not tag an adjacent pursuer")

    ctx:destroy(rat)
    ctx:destroy(player)
end

-- Allied followers can form a short line while no unfriendly actor is
-- adjacent. A pursuer next to the stair reduces that source radius to one.
local function friendly_chain_and_hostile_radius(ctx)
    local game = stair_context(ctx)
    local first = candidate(ctx, monsters.MONS_ORC, 8, 7)
    local second = candidate(ctx, monsters.MONS_ORC, 9, 7)
    local third = candidate(ctx, monsters.MONS_ORC, 10, 7)

    friendly(ctx, first)
    friendly(ctx, second)
    friendly(ctx, third)
    action.run(game, { stair_travel = true })
    harness.truthy(game:has(third, component.MONSTER_STAIR_FOLLOWER),
        "connected friendly chain stopped too early")

    for _, entity in ipairs({ first, second, third }) do
        game:remove(entity, component.MONSTER_STAIR_FOLLOWER)
    end

    local hostile = candidate(ctx, monsters.MONS_RAT, 7, 8)

    action.run(game, { stair_travel = true })
    harness.truthy(game:has(first, component.MONSTER_STAIR_FOLLOWER))
    harness.falsy(game:has(second, component.MONSTER_STAIR_FOLLOWER),
        "distant friend followed past an adjacent hostile")

    for _, entity in ipairs({ first, second, third, hostile }) do
        ctx:destroy(entity)
    end

    ctx:destroy(game:player())
end

-- A low-energy, paralysed, stationary, or summoned body remains on its
-- current floor even when adjacent and otherwise seeking the player.
local function excluded_bodies(ctx)
    local game = stair_context(ctx)
    local low = candidate(ctx, monsters.MONS_RAT, 8, 7, 49)
    local paralysed = candidate(ctx, monsters.MONS_RAT, 7, 8)
    local stationary = candidate(ctx, monsters.MONS_PLANT, 6, 7)
    local summoned = candidate(ctx, monsters.MONS_RAT, 7, 6)

    ctx:add(paralysed, component.PARALYSIS, {
        remaining_aut = 10,
    })
    ctx:add(summoned, component.SUMMON, {
        owner = game:player(),
        attitude = attitudes.FRIENDLY,
    })

    action.run(game, { stair_travel = true })

    for _, entity in ipairs({ low, paralysed, stationary, summoned }) do
        harness.falsy(game:has(entity, component.MONSTER_STAIR_FOLLOWER),
            "ineligible body took a stair")
        ctx:destroy(entity)
    end

    ctx:destroy(game:player())
end

-- The follower mark means the monster cannot attack or move between the
-- accepted command and the actual world.stairs transfer phase.
local function marked_monster_waits(ctx)
    local game = stair_context(ctx)
    local rat = candidate(ctx, monsters.MONS_RAT, 8, 7)

    action.run(game, { stair_travel = true })
    decision.update(game, rat)
    harness.falsy(game:has(rat, component.INTENT),
        "marked monster acted during the stair delay")

    ctx:destroy(rat)
    ctx:destroy(game:player())
end

-- Adjacent hostility alone does not make a pursuer: source requires the
-- monster to be seeking the player rather than a different target.
local function unrelated_hostile_stays(ctx)
    local game = stair_context(ctx)
    local rat = candidate(ctx, monsters.MONS_RAT, 8, 7)
    local ai = game:get(rat, component.AI)

    ai.target_x = 15
    ai.target_y = 15
    game:set(rat, component.AI, ai)
    action.run(game, { stair_travel = true })

    harness.falsy(game:has(rat, component.MONSTER_STAIR_FOLLOWER),
        "unrelated hostile followed the player")

    ctx:destroy(rat)
    ctx:destroy(game:player())
end

-- Two live twins must climb together. If one is out of reach, neither
-- leaves; once one is gone, the survivor needs its saved grief allowance.
local function twins_climb_together(ctx)
    local game = stair_context(ctx)
    local duvessa = candidate(ctx, monsters.MONS_DUVESSA, 8, 7)
    local dowan = candidate(ctx, monsters.MONS_DOWAN, 7, 8)

    local changed = game:get(dowan, component.ACTOR)

    changed.kind_id = monsters.MONS_ORC
    game:set(dowan, component.ACTOR, changed)
    game:add(dowan, component.MONSTER_POLYMORPH, {
        original_kind_id = monsters.MONS_DOWAN,
    })

    action.run(game, { stair_travel = true })
    harness.truthy(game:has(duvessa, component.MONSTER_STAIR_FOLLOWER))
    harness.truthy(game:has(dowan, component.MONSTER_STAIR_FOLLOWER))

    game:remove(duvessa, component.MONSTER_STAIR_FOLLOWER)
    game:remove(dowan, component.MONSTER_STAIR_FOLLOWER)
    game:move_actor(dowan, 1, 9, 7)
    action.run(game, { stair_travel = true })
    harness.falsy(game:has(duvessa, component.MONSTER_STAIR_FOLLOWER),
        "one twin climbed while the other was out of reach")

    ctx:destroy(dowan)
    action.run(game, { stair_travel = true })
    harness.falsy(game:has(duvessa, component.MONSTER_STAIR_FOLLOWER),
        "lone twin climbed without grief")

    game:add(duvessa, component.MONSTER_ELVEN_TWIN, {
        grieved = true,
        pending = false,
        energized = true,
        can_climb = true,
        cause = twin_causes.DEATH,
    })
    action.run(game, { stair_travel = true })
    harness.truthy(game:has(duvessa, component.MONSTER_STAIR_FOLLOWER),
        "grieving survivor could not climb")

    ctx:destroy(duvessa)
    ctx:destroy(game:player())
end

-- The source caps real companions at 18 even when a larger connected
-- friendly crowd waits around the player.
local function follower_limit(ctx)
    local game = stair_context(ctx)
    local actors = {}

    for y = 5, 9 do
        for x = 5, 9 do
            if x ~= 7 or y ~= 7 then
                local entity = candidate(ctx, monsters.MONS_ORC,
                    x, y)

                friendly(ctx, entity)
                actors[#actors + 1] = entity
            end
        end
    end

    action.run(game, { stair_travel = true })

    local tagged = 0

    for _, entity in ipairs(actors) do
        if game:has(entity, component.MONSTER_STAIR_FOLLOWER) then
            tagged = tagged + 1
        end

        ctx:destroy(entity)
    end

    harness.equal(tagged, 18, "source stair follower cap changed")
    ctx:destroy(game:player())
end

-- A refusal, ordinary floor, and a disconnected branch do not start a
-- follower wave merely because a command mentioned a stair.
local function unavailable_stair_and_branch(ctx)
    local game = stair_context(ctx)
    local rat = candidate(ctx, monsters.MONS_RAT, 8, 7)

    action.run(game, { stair_travel = false })
    harness.falsy(game:has(rat, component.MONSTER_STAIR_FOLLOWER))

    -- Even an accepted flag cannot turn ordinary floor into a stair.
    function game:cell()
        return terrain.DNGN_FLOOR
    end

    action.run(game, { stair_travel = true })
    harness.falsy(game:has(rat, component.MONSTER_STAIR_FOLLOWER))

    -- Restore the link to test the branch restriction independently.
    function game:cell(_, x, y)
        if x == 7 and y == 7 then
            return terrain.DNGN_STONE_STAIRS_DOWN_I
        end

        return terrain.DNGN_FLOOR
    end

    -- Ossuary prohibits ordinary cross-level followers.
    function game:level_branch()
        return branches.BRANCH_OSSUARY
    end

    action.run(game, { stair_travel = true })
    harness.falsy(game:has(rat, component.MONSTER_STAIR_FOLLOWER),
        "a disconnected branch carried an ordinary follower")

    ctx:destroy(rat)
    ctx:destroy(game:player())
end

-- The follower stays the same Akara actor after travel. A mark is one
-- action's control state and must not survive the destination save.
local function transfer_preserves_identity(ctx)
    local game = stair_context(ctx)
    local rat = candidate(ctx, monsters.MONS_RAT, 8, 7)
    local player = game:player()
    local origin = game:get(player, component.POSITION)

    action.run(game, { stair_travel = true })
    game:move_actor(player, 2, 7, 7)
    followers.transfer(game, player, origin, 2, 7, 7)

    local position = game:get(rat, component.POSITION)

    harness.equal(position.level_id, 2)
    harness.truthy(math.max(math.abs(position.x - 7),
        math.abs(position.y - 7)) <= 1)
    harness.falsy(game:has(rat, component.MONSTER_STAIR_FOLLOWER))
    harness.equal(game:get(rat, component.ACTOR).kind_id,
        monsters.MONS_RAT)

    ctx:destroy(rat)
    ctx:destroy(player)
end

-- A packed arrival cannot delete a follower or make the player's stair
-- command fail. The actor stays on its old floor for a later encounter.
local function blocked_destination_retains_follower(ctx)
    local game = stair_context(ctx)
    local rat = candidate(ctx, monsters.MONS_RAT, 8, 7)
    local player = game:player()
    local origin = game:get(player, component.POSITION)

    action.run(game, { stair_travel = true })

    -- Occupy the only connected landing cell with the player.
    function game:walkable(level_id, x, y)
        if level_id == 2 then
            return x == 7 and y == 7
        end

        return true
    end

    game:move_actor(player, 2, 7, 7)
    followers.transfer(game, player, origin, 2, 7, 7)

    harness.equal(game:get(rat, component.POSITION).level_id, 1)
    harness.falsy(game:has(rat, component.MONSTER_STAIR_FOLLOWER))

    ctx:destroy(rat)
    ctx:destroy(player)
end

-- Successive placements must see occupancy written earlier in the same
-- action, so a friendly pair never materializes on one destination cell.
local function two_followers_take_distinct_cells(ctx)
    local game = stair_context(ctx)
    local player = game:player()
    local origin = game:get(player, component.POSITION)
    local first = candidate(ctx, monsters.MONS_ORC, 8, 7)
    local second = candidate(ctx, monsters.MONS_ORC, 9, 7)

    friendly(ctx, first)
    friendly(ctx, second)
    action.run(game, { stair_travel = true })
    game:move_actor(player, 2, 7, 7)
    harness.equal(followers.transfer(game, player, origin, 2, 7, 7), 2)

    local a = game:get(first, component.POSITION)
    local b = game:get(second, component.POSITION)

    harness.equal(a.level_id, 2)
    harness.equal(b.level_id, 2)
    harness.falsy(a.x == b.x and a.y == b.y,
        "two followers occupied one arrival cell")

    ctx:destroy(first)
    ctx:destroy(second)
    ctx:destroy(player)
end

-- Run all rules against shared component definitions and the production
-- command boundary so the test cannot drift into a second stair schema.
function test.run(ctx)
    accepted_stair_tags_pursuer(ctx)
    friendly_chain_and_hostile_radius(ctx)
    excluded_bodies(ctx)
    marked_monster_waits(ctx)
    unrelated_hostile_stays(ctx)
    twins_climb_together(ctx)
    follower_limit(ctx)
    unavailable_stair_and_branch(ctx)
    transfer_preserves_identity(ctx)
    blocked_destination_retains_follower(ctx)
    two_followers_take_distinct_cells(ctx)
end

return test
