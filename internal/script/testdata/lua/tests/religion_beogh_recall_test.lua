-- Recall queues actual Beogh companion entities and moves them through
-- the grid owner. Its timer and queue must survive an ordinary save.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local branches = require("ids.branches")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local recall = require("policy.abilities.beogh.recall")
local species = require("ids.species")
local fixture = require("tests.monster_ally_support_fixture")

local test = {}

-- Production components represent one worshipper and two saved orc gifts.
-- The high-HD orc begins on another Dungeon level to test cross-floor move.
local function companions(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 10, 10,
        40)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HILL_ORC,
        job_id = jobs.JOB_FIGHTER,
        name = "Recall tester",
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.BEOGH,
        piety = 120,
    })

    local game = fixture.context(ctx, player)
    local high = fixture.actor(ctx, monsters.MONS_ORC_KNIGHT,
        20, 20)
    local low = fixture.actor(ctx, monsters.MONS_ORC, 18, 10)

    ctx:set(high, component.POSITION, {
        level_id = 2,
        x = 20,
        y = 20,
    })

    for _, entity in ipairs({ high, low }) do
        ctx:add(entity, component.BEOGH_ORC, {
            attitude = attitudes.FRIENDLY,
            attempted = true,
            gift = true,
        })
        ctx:add(entity, component.AI, {
            behavior = "wander",
        })
    end

    function game:random()
        return 0
    end

    return game, player, high, low
end

-- Source recall sorts by experience plus a ten-sided draw. One aut starts
-- the queue, places its first member near the player, and saves the delay.
local function timed_and_cross_level(game, player, high, low)
    harness.truthy(recall.start(game, player))

    local state = game:get(player, component.BEOGH_RECALL)

    harness.equal(state.queue[1], high)
    harness.equal(state.queue[2], low)
    recall.validate(game, player)

    recall.tick(game, player, 1)

    local position = game:get(high, component.POSITION)

    harness.equal(position.level_id, 1)
    harness.truthy(math.max(math.abs(position.x - 10),
        math.abs(position.y - 10)) <= 3)
    harness.equal(game:get(player, component.BEOGH_RECALL).next_index,
        2)

    recall.stop(game, player)
    harness.falsy(game:has(player, component.BEOGH_RECALL))
end

-- The ordinary lifecycle and the save validator share one queue contract.
function test.run(ctx)
    local game, player, high, low = companions(ctx)

    -- A gift left in an isolated branch may answer from Dungeon. Only
    -- Abyss companions are excluded by the source off-level roster.
    function game:level_branch(level_id)
        if level_id == 2 then
            return branches.BRANCH_GAUNTLET
        end

        return branches.BRANCH_DUNGEON
    end

    harness.truthy(recall.start(game, player))
    harness.equal(game:get(player, component.BEOGH_RECALL).queue[1],
        high)
    recall.stop(game, player)
    game.level_branch = nil

    timed_and_cross_level(game, player, high, low)
end

return test
