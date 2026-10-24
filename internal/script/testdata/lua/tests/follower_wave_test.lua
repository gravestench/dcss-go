-- Stair and transporter followers use the same source connected wave while
-- keeping different body permissions. These cases read real ECS schemas.
local attitudes = require("constants.attitude")
local behaviors = require("constants.ai_behaviors")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local modes = require("constants.follower_travel")
local monsters = require("ids.monsters")
local wave = require("policy.world.follower_wave")

local test = {}

-- The shared sparse fixture supplies the same bounds the production grid
-- exposes; all actual AI, energy, and actor components come from Akara.
local function floor(ctx)
    local game = fixture.observed_context(ctx)

    -- Bound a sparse grid exactly as the live level service does.
    function game:level_size()
        return 20, 20
    end

    return game
end

-- Every candidate starts actively seeking the player's current square.
-- Tests alter one component at a time to isolate a source follower gate.
local function candidate(ctx, kind_id, x, y, energy)
    local entity = fixture.actor(ctx, kind_id, x, y)

    ctx:add(entity, component.AI, {
        behavior = behaviors.SEEK,
        target_x = 7,
        target_y = 7,
        memory_until_aut = 250,
        bat_retreat_actions = 0,
    })
    ctx:add(entity, component.MONSTER_ENERGY, {
        points = energy or 70,
    })

    return entity
end

-- A permanent ally participates in the source's connected chain, while
-- an unrelated hostile must still prove it is actually pursuing the player.
local function friendly(ctx, entity)
    ctx:add(entity, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })
end

-- The actor order comes from source cells, not creation/query order. The
-- source also lets a friend connect the next friend out to five cells.
local function spatial_chain(ctx)
    local game = floor(ctx)
    local east = candidate(ctx, monsters.MONS_RAT, 8, 7)
    local farther = candidate(ctx, monsters.MONS_RAT, 9, 7)
    local north = candidate(ctx, monsters.MONS_RAT, 7, 6)

    friendly(ctx, east)
    friendly(ctx, farther)
    friendly(ctx, north)

    local selected = wave.select(game, game:player(),
        game:get(game:player(), component.POSITION), modes.TRANSPORTER)

    harness.equal(selected[1], north,
        "follower wave used ECS creation order")
    harness.equal(selected[2], east)
    harness.equal(selected[3], farther)

    for _, entity in ipairs({ east, farther, north, game:player() }) do
        ctx:destroy(entity)
    end
end

-- Incapacitated or energy-starved actors cannot follow. An adjacent
-- hostile narrows the friendly chain; seeking a different cell is not
-- enough to turn that hostile into a real follower.
local function status_and_pursuit(ctx)
    local game = floor(ctx)
    local tired = candidate(ctx, monsters.MONS_RAT, 8, 7, 49)
    local paralysed = candidate(ctx, monsters.MONS_RAT, 7, 8)
    local unrelated = candidate(ctx, monsters.MONS_RAT, 6, 7)
    local friend = candidate(ctx, monsters.MONS_RAT, 8, 6)
    local farther = candidate(ctx, monsters.MONS_RAT, 9, 6)

    game:add(paralysed, component.PARALYSIS, {
        remaining_aut = 10,
    })
    friendly(ctx, friend)
    friendly(ctx, farther)

    local ai = game:get(unrelated, component.AI)

    ai.target_x = 15
    ai.target_y = 15
    game:set(unrelated, component.AI, ai)

    local selected = wave.select(game, game:player(),
        game:get(game:player(), component.POSITION), modes.TRANSPORTER)

    harness.equal(#selected, 1,
        "status, unrelated pursuit, or hostile radius admitted a follower")
    harness.equal(selected[1], friend)

    for _, entity in ipairs({ tired, paralysed, unrelated,
        friend, farther, game:player() }) do
        ctx:destroy(entity)
    end
end

-- Source transporter passage can take a summon or zombified body that
-- ordinary stairs cannot. Neither mode can carry tentacle segments.
local function mode_specific_bodies(ctx)
    local game = floor(ctx)
    local summon = candidate(ctx, monsters.MONS_RAT, 8, 7)
    local zombie = candidate(ctx, monsters.MONS_ZOMBIE, 7, 8)
    local tentacle = candidate(ctx,
        monsters.MONS_KRAKEN_TENTACLE, 6, 7)

    for _, entity in ipairs({ summon, zombie, tentacle }) do
        friendly(ctx, entity)
    end

    game:add(summon, component.SUMMON, {
        owner = game:player(),
        attitude = attitudes.FRIENDLY,
    })

    local origin = game:get(game:player(), component.POSITION)
    local transporter = wave.select(game, game:player(),
        origin, modes.TRANSPORTER)
    local stairs = wave.select(game, game:player(),
        origin, modes.STAIRS)

    harness.equal(#transporter, 2)
    harness.equal(#stairs, 0)

    for _, entity in ipairs({ summon, zombie, tentacle,
        game:player() }) do
        ctx:destroy(entity)
    end
end

-- Each case can be read independently and uses the same production wave.
function test.run(ctx)
    spatial_chain(ctx)
    status_and_pursuit(ctx)
    mode_specific_bodies(ctx)
end

return test
