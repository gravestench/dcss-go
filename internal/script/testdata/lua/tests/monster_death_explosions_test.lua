-- Source monsters that die explosively must resolve their effect through
-- actor.death, including a summon that reaches its saved expiry time.
local component = require("constants.component")
local death = require("systems.actor_death")
local expiry = require("systems.magic_summon_expiry")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local save_monsters = require("policy.save.monsters")
local spells = require("ids.spells")

local test = {}

-- The source fixture supplies actor identity and health. Save validation
-- additionally expects every live actor to have its combat store.
local function actor(ctx, kind_id, x, y, health)
    local entity = fixture.actor(ctx, kind_id, x, y, health)

    ctx:add(entity, component.COMBAT, {
        shield_blocks = 0,
    })

    return entity
end

-- Test actors use real ECS stores and the fixture's simple open grid. The
-- player stands outside every blast, so collateral assertions inspect rats.
local function world(ctx)
    local player = actor(ctx, monsters.MONS_HUMAN,
        60, 60, 100)
    local game = fixture.context(ctx, player)

    ctx:add(player, component.PLAYER, {})

    function game:random(_, bound)
        harness.truthy(bound > 0, "invalid explosion draw")

        return 0
    end

    function game:aut()
        return self.current_aut or 0
    end

    return game, player
end

-- Exercise the scheduler's death owner rather than invoking a new policy
-- directly. It must remove the dying actor and still reach blast victims.
local function kill(ctx, game, actor)
    local health = ctx:get(actor, component.HEALTH)

    health.current = 0
    ctx:set(actor, component.HEALTH, health)
    death.update(game)
end

-- Each creature's source death effect has its own damage shape. A blast
-- victim starts at 100 HP so the death pass cannot consume it accidentally.
local function death_damage(ctx, game, kind_id, x, y)
    local source = actor(ctx, kind_id, x, y, 20)
    local victim = actor(ctx, monsters.MONS_RAT,
        x + 1, y, 100)

    kill(ctx, game, source)

    harness.truthy(ctx:get(victim, component.HEALTH).current < 100,
        kind_id .. " death did not hurt its neighbor")

    return source
end

-- A charged prism uses the source's weaker first-charge blast. An
-- uncharged prism dies quietly, and a ball detonates when killed early.
local function constructs(ctx, game, player)
    local ball = actor(ctx, monsters.MONS_BALL_LIGHTNING,
        5, 5, 20)
    local ball_victim = actor(ctx, monsters.MONS_RAT,
        6, 5, 100)

    ctx:add(ball, component.SUMMON, {
        owner = player,
        source_id = spells.SPELL_CONJURE_BALL_LIGHTNING,
        expires_aut = 60,
    })
    ctx:add(ball, component.SUMMON_STATS, { hd = 4 })
    ctx:add(ball, component.SUMMON_CONSTRUCT, {
        power = 60,
        charge = 0,
    })

    kill(ctx, game, ball)
    harness.truthy(ctx:get(ball_victim, component.HEALTH).current < 100,
        "killed ball lightning failed to explode")

    local prism = actor(ctx, monsters.MONS_FULMINANT_PRISM,
        15, 5, 20)
    local prism_victim = actor(ctx, monsters.MONS_RAT,
        16, 5, 100)

    ctx:add(prism, component.SUMMON, {
        owner = player,
        source_id = spells.SPELL_FULMINANT_PRISM,
        expires_aut = 60,
    })
    ctx:add(prism, component.SUMMON_CONSTRUCT, {
        power = 50,
        charge = 1,
    })

    kill(ctx, game, prism)
    harness.truthy(ctx:get(prism_victim, component.HEALTH).current < 100,
        "charged prism failed to explode on death")

    local quiet = actor(ctx, monsters.MONS_FULMINANT_PRISM,
        25, 5, 20)
    local quiet_victim = actor(ctx, monsters.MONS_RAT,
        26, 5, 100)

    ctx:add(quiet, component.SUMMON, {
        owner = player,
        source_id = spells.SPELL_FULMINANT_PRISM,
        expires_aut = 60,
    })
    ctx:add(quiet, component.SUMMON_CONSTRUCT, {
        power = 50,
        charge = 0,
    })

    kill(ctx, game, quiet)
    harness.equal(ctx:get(quiet_victim, component.HEALTH).current, 100,
        "uncharged prism exploded")
end

-- A timed-out ball must reach the same death path as a lethal hit. Expiry
-- currently runs before actor.death and can otherwise erase the construct.
local function timed_ball(ctx, game, player)
    local ball = actor(ctx, monsters.MONS_BALL_LIGHTNING,
        35, 5, 20)
    local victim = actor(ctx, monsters.MONS_RAT,
        36, 5, 100)

    ctx:add(ball, component.SUMMON, {
        owner = player,
        source_id = spells.SPELL_CONJURE_BALL_LIGHTNING,
        expires_aut = 10,
    })
    ctx:add(ball, component.SUMMON_STATS, { hd = 4 })
    ctx:add(ball, component.SUMMON_CONSTRUCT, {
        power = 60,
        charge = 0,
    })

    game.current_aut = 10
    expiry.update(game, player)
    death.update(game)

    harness.truthy(ctx:get(victim, component.HEALTH).current < 100,
        "timed-out ball lightning disappeared without exploding")
end

-- Torment cannot kill, but a nearby susceptible monster should lose HP.
-- The husk's physical blast likewise hurts a neighboring rat.
local function natural_deaths(ctx, game)
    death_damage(ctx, game, monsters.MONS_BLOATED_HUSK,
        5, 15)
    death_damage(ctx, game, monsters.MONS_LURKING_HORROR,
        15, 15)
end

-- Bennu's first explosion is followed by a new body in its former cell.
-- Its saved revival count prevents a third body after the second death.
local function bennu_once(ctx, game)
    local first = actor(ctx, monsters.MONS_BENNU,
        30, 15, 20)
    local victim = actor(ctx, monsters.MONS_RAT,
        31, 15, 100)

    kill(ctx, game, first)

    harness.truthy(ctx:get(victim, component.HEALTH).current < 100,
        "Bennu death omitted its negative-energy pyre")

    local second = game:actor_at(1, 30, 15)

    harness.truthy(second and second ~= first,
        "Bennu did not revive in its previous cell")
    harness.equal(ctx:get(second, component.ACTOR).kind_id,
        monsters.MONS_BENNU, "Bennu revival kind")
    harness.equal(ctx:get(second, component.BENNU_REVIVAL).revives,
        1, "Bennu saved revival count")

    local save_input = {
        scenario_id = "generated-dungeon-basic-v1",
        current_aut = 10,
        player_alive = true,
        levels = {
            {
                id = 1,
                initial_actors = 100,
            },
        },
    }

    save_monsters.run(game, save_input)

    ctx:set(second, component.BENNU_REVIVAL, {
        revives = 2,
    })
    harness.falsy(pcall(save_monsters.run, game, save_input),
        "impossible Bennu revival count passed restore validation")
    ctx:set(second, component.BENNU_REVIVAL, {
        revives = 1,
    })

    kill(ctx, game, second)
    harness.falsy(game:actor_at(1, 30, 15),
        "Bennu revived beyond its second life")
end

-- Cover all remaining intrinsic death effects with the real ECS death and
-- expiry systems; each category has a separate assertion above.
function test.run(ctx)
    local game, player = world(ctx)

    constructs(ctx, game, player)
    timed_ball(ctx, game, player)
    natural_deaths(ctx, game)
    bennu_once(ctx, game)
end

return test
