-- Two current marks model a split opponent. The authored B barrier opens
-- only when the final living lineage body dies.
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local terrain = require("constants.terrain")
local victory = require("policy.world.arena.victory")
local abyss = require("policy.world.abyss")
local forced = require("policy.world.forced_portal")
local gods = require("constants.gods")

local test = {}

-- This calls the registered death owner with production ECS records and
-- the shared sparse-grid fixture used by other combat rule tests.
function test.run(ctx)
    local game = fixture.observed_context(ctx)
    local player = game:player()
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.OKAWARU,
        piety = 200,
    })
    local first = fixture.actor(ctx, monsters.MONS_OGRE,
        8, 7, 10)
    local second = fixture.actor(ctx, monsters.MONS_OGRE,
        9, 7, 10)
    local barrier = { level_id = 1, x = 8, y = 9 }

    game.cells["8:9"] = terrain.DNGN_CLEAR_PERMAROCK_WALL
    ctx:add(player, component.PLAYER_ARENA_VISIT, {
        origin_level_id = 2,
        origin_x = 5,
        origin_y = 5,
        level_id = 1,
        vault_id = "okawaru_arena_1",
        target_id = tostring(ctx:id(first)),
        target_x = barrier.x,
        target_y = barrier.y,
        exit_x = 8,
        exit_y = 10,
        victory = false,
    })

    for _, monster in ipairs({ first, second }) do
        ctx:add(monster, component.MONSTER_ARENA_DUEL, {
            current = true,
            abandoned = false,
            root_id = tostring(ctx:id(first)),
        })
    end

    local first_site = ctx:get(first, component.POSITION)
    local second_site = ctx:get(second, component.POSITION)
    local first_health = ctx:get(first, component.HEALTH)

    first_health.current = 0
    ctx:set(first, component.HEALTH, first_health)

    victory.on_death(game, first, {}, first_site)
    harness.equal(game:cell(1, barrier.x, barrier.y),
        terrain.DNGN_CLEAR_PERMAROCK_WALL)

    local health = ctx:get(second, component.HEALTH)

    health.current = 0
    ctx:set(second, component.HEALTH, health)
    victory.on_death(game, second, {}, second_site)
    harness.equal(game:cell(1, barrier.x, barrier.y),
        terrain.DNGN_FLOOR)
    harness.truthy(ctx:get(player,
        component.PLAYER_ARENA_VISIT).victory)
    local won = ctx:get(player, component.PLAYER_ARENA_VISIT)

    harness.truthy(won.return_aut >= 150 and won.return_aut <= 250)
    harness.falsy(forced.pending(game).portal)
    victory.tick(game, player, won.return_aut)
    harness.truthy(forced.pending(game).portal)

    -- Source player banishment is vetoed in Arena; an opponent's
    -- banishment instead releases its lineage and opens the barrier.
    local player_site = ctx:get(player, component.POSITION)

    abyss.banish(game, player)
    harness.equal(ctx:get(player, component.POSITION).level_id,
        player_site.level_id)

    local third = fixture.actor(ctx, monsters.MONS_OGRE,
        8, 7, 10)
    local pending = ctx:get(player, component.PLAYER_ARENA_VISIT)

    pending.victory = false
    pending.return_aut = 0
    ctx:set(player, component.PLAYER_ARENA_VISIT, pending)
    game.cells["8:9"] = terrain.DNGN_CLEAR_PERMAROCK_WALL
    ctx:add(third, component.MONSTER_ARENA_DUEL, {
        current = true,
        abandoned = false,
        root_id = tostring(ctx:id(first)),
    })

    local return_site = victory.on_departure(game, third,
        ctx:get(third, component.POSITION))
    local third_mark = ctx:get(third, component.MONSTER_ARENA_DUEL)

    harness.equal(return_site.level_id, 2)
    harness.falsy(third_mark.current)
    harness.truthy(third_mark.abandoned)
    harness.equal(game:cell(1, barrier.x, barrier.y),
        terrain.DNGN_FLOOR)
end

return test
