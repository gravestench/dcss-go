-- Jiyva's sixth star opens the same authored Slime seal as the Royal
-- Jelly's death. These tests use production worship and seal components.
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local fixture = require("tests.monster_ally_support_fixture")
local monsters = require("ids.monsters")
local names = require("constants.slime_pit")
local piety = require("policy.religion.piety")
local population = require("policy.population.slime_seal")
local royal_jelly = require("policy.combat.monster_death.slime_pit")
local slime_seals = require("policy.world.slime_seals")
local statuses = require("policy.magic.effects.statuses.player")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local test = {}

-- Force only the piety taper to accept a point. All other game RNG still
-- uses the real ECS context, so the test exercises the production path.
local function world(ctx)
    local player = ctx:create()

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.JIYVA,
        piety = 159,
    })

    local game = fixture.context(ctx, player)

    game.messages = {}

    function game:random(stream, bound)
        if stream == streams.RELIGION and bound == 3 then
            return 1
        end

        return self.base:random(stream, bound)
    end

    function game:set_cell(_, x, y, feature)
        self.cells[x .. ":" .. y] = feature
    end

    function game:emit(_, message)
        self.messages[#self.messages + 1] = message
    end

    function game:remembered()
        return nil
    end

    return game, player
end

-- Materialize the real authored seal component rather than copying its
-- shape into the test. Source markers keep the wall and its identity tied.
local function seal(game, level_id, index, x)
    local level = {
        id = level_id,
    }
    local record = {
        index = index,
        x = x,
        y = 10,
    }

    game:set_cell(level_id, x, 10, terrain.DNGN_CLEAR_STONE_WALL)
    population.materialize(game, level, record)
end

-- The exact rank boundary spends the one-time reward and opens the current
-- floor. Further piety gains cannot send the announcement or open it again.
local function current_floor_reward(ctx)
    local game, player = world(ctx)

    seal(game, 1, 1, 12)
    seal(game, 1, 2, 13)

    piety.gain(game, player, 1, 1, false)

    local worship = game:get(player, component.RELIGION_WORSHIP)

    harness.equal(worship.piety, 160)
    harness.truthy(worship.one_time_abilities and
        worship.one_time_abilities[gods.JIYVA],
        "sixth-star vault reward was not saved")
    harness.equal(game:cell(1, 12, 10), terrain.DNGN_FLOOR)
    harness.equal(game:cell(1, 13, 10), terrain.DNGN_FLOOR)
    harness.equal(game.messages[1],
        "Jiyva will now unseal the treasures of the Slime Pits.")
    harness.equal(game.messages[2],
        "You hear the sound of toppling stones.")

    piety.gain(game, player, 1, 1, false)
    harness.equal(#game.messages, 2)
end

-- Source dgn.persist waits for an entered-level event when the final map
-- was not active as piety crossed six stars. That visit opens its seals.
local function delayed_floor_reward(ctx)
    local game, player = world(ctx)

    seal(game, 2, 1, 14)
    piety.gain(game, player, 1, 1, false)

    harness.equal(game:cell(2, 14, 10),
        terrain.DNGN_CLEAR_STONE_WALL)

    game:set(player, component.POSITION, {
        level_id = 2,
        x = 1,
        y = 1,
    })

    slime_seals.enter(game, 2)

    harness.equal(game:cell(2, 14, 10), terrain.DNGN_FLOOR)
    harness.equal(game.messages[2],
        "You hear the sound of toppling stones.")

    slime_seals.enter(game, 2)
    harness.equal(#game.messages, 2)
end

-- Paying Jiyva's last debt at rank six rechecks the passive even though
-- that point did not cross another rank threshold.
local function penance_reward(ctx)
    local game, player = world(ctx)
    local state = game:get(player, component.RELIGION_WORSHIP)

    state.piety = 160
    state.penance[gods.JIYVA] = 1
    game:set(player, component.RELIGION_WORSHIP, state)
    seal(game, 1, 1, 15)

    piety.gain(game, player, 1, 1, false)

    state = game:get(player, component.RELIGION_WORSHIP)

    harness.truthy(state.one_time_abilities[gods.JIYVA])
    harness.equal(game:cell(1, 15, 10), terrain.DNGN_FLOOR)
end

-- The reward outlives worship. Remembering a wall is different from seeing
-- it now: the source only describes a visible collapse at the current LOS.
local function abandoned_reward(ctx)
    local game, player = world(ctx)

    seal(game, 2, 1, 16)
    piety.gain(game, player, 1, 1, false)

    local state = game:get(player, component.RELIGION_WORSHIP)

    state.god_id = gods.NO_GOD
    game:set(player, component.RELIGION_WORSHIP, state)
    game:set(player, component.POSITION, {
        level_id = 2,
        x = 1,
        y = 1,
    })

    function game:remembered()
        return terrain.DNGN_CLEAR_STONE_WALL
    end

    function game:visible()
        return false
    end

    slime_seals.enter(game, 2)

    harness.equal(game.messages[2],
        "You feel a strange vibration for a moment.")
end

-- The source chooses its god message from current worship even if the
-- Royal Jelly, rather than a piety crossing, triggered the wall release.
local function royal_jelly_under_jiyva(ctx)
    local game, player = world(ctx)
    local worship = game:get(player, component.RELIGION_WORSHIP)

    worship.piety = 160
    game:set(player, component.RELIGION_WORSHIP, worship)
    seal(game, 1, 1, 17)

    local monster = fixture.actor(ctx, monsters.MONS_ROYAL_JELLY,
        5, 10, 100)

    ctx:add(monster, component.VAULT_ORIGIN, {
        level_id = 1,
        vault_id = names.MAP_ID,
        record_index = 3,
        occurrence = 1,
        spawn_x = 5,
        spawn_y = 10,
        kind_id = monsters.MONS_ROYAL_JELLY,
    })

    royal_jelly.on_death(game, monster)

    harness.equal(game.messages[1],
        "You hear the sound of toppling stones.")
end

-- Silence changes only how a devoted Jiyva follower perceives the same
-- release; it still spends the reward and removes the authored wall.
local function silent_reward(ctx)
    local game, player = world(ctx)

    seal(game, 1, 1, 18)
    statuses.add_silence(game, player, 10, 10)
    piety.gain(game, player, 1, 1, false)

    harness.equal(game:cell(1, 18, 10), terrain.DNGN_FLOOR)
    harness.equal(game.messages[2],
        "You feel a strange vibration for a moment.")
end

-- Each case has its own player context while sharing production schemas.
function test.run(ctx)
    current_floor_reward(ctx)
    delayed_floor_reward(ctx)
    penance_reward(ctx)
    abandoned_reward(ctx)
    royal_jelly_under_jiyva(ctx)
    silent_reward(ctx)
end

return test
