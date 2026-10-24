-- Apocalypse attacks every visible nonfriendly target through the ordinary
-- monster health owner and keeps its continuing effect in saved ECS state.
local abilities = require("ids.abilities")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local ru_power = require("policy.abilities.ru.apocalypse")
local registry = require("policy.abilities.registry")
local species = require("ids.species")
local tactical = require("constants.monster_tactical")

local test = {}

-- With no foes, confirmation is free. A deterministic Slow branch then
-- proves the damage, status, drain, MP, and exhaustion all commit together.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        10, 10, 30)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Apocalypse tester",
    })
    ctx:add(player, component.PROGRESSION, {
        level = 10,
        total_xp = 3910,
        pending_stat_level = 0,
    })
    ctx:add(player, component.MAGIC, {
        current = 10,
        max = 10,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.RU,
        piety = 120,
    })

    local game = fixture.context(ctx, player)
    local apocalypse = registry.get(abilities.RU_APOCALYPSE)

    harness.truthy(apocalypse ~= nil)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.piety = 119
    ctx:set(player, component.RELIGION_WORSHIP, worship)
    harness.truthy(not registry.usable_now(game, player,
        apocalypse))
    worship.piety = 120
    ctx:set(player, component.RELIGION_WORSHIP, worship)

    harness.truthy(registry.usable_now(game, player, apocalypse))

    local empty = apocalypse.prepare(game, player, {
        forced = false,
    })

    harness.equal(empty.confirmation_id, abilities.RU_APOCALYPSE)
    harness.equal(ctx:get(player, component.MAGIC).current, 10)

    local foe = fixture.actor(ctx, monsters.MONS_ORC,
        12, 10, 100)

    -- Source random2(4)=2 chooses Slow. Other zero draws give the minimum
    -- damage and duration, keeping this actor alive for status inspection.
    function game:random(_, bound)
        if bound == 4 then
            return 2
        end

        return 0
    end

    harness.equal(apocalypse.prepare(game, player, {}), nil)
    apocalypse.resolve(game, player)

    local slow = ctx:get(foe, component.PROJECTILE_SLOW)
    local exhausted = ctx:get(player, component.PLAYER_EXHAUSTION)

    harness.truthy(ctx:get(foe, component.HEALTH).current < 100)
    harness.truthy(slow ~= nil and slow.remaining_aut > 0)
    harness.equal(ctx:get(player, component.MAGIC).current, 2)
    harness.truthy(ctx:has(player, component.PLAYER_DRAIN))
    harness.truthy(exhausted.remaining_aut >= 300 and
        exhausted.remaining_aut <= 490)

    -- A second paid cast takes the Paralysis branch without replacing the
    -- saved Slow timer. Both statuses belong to the monster's ECS state.
    ctx:remove(player, component.PLAYER_EXHAUSTION)

    local magic = ctx:get(player, component.MAGIC)

    magic.current = 10
    ctx:set(player, component.MAGIC, magic)

    function game:random(_, bound)
        if bound == 4 then
            return 1
        end

        return 0
    end

    apocalypse.resolve(game, player)
    harness.truthy(ctx:has(foe, component.PARALYSIS))
    harness.truthy(ctx:has(foe, component.PROJECTILE_SLOW))

    local first_paralysis = ctx:get(foe,
        component.PARALYSIS).remaining_aut

    -- A repeated enchantment adds its duration as in DCSS's monster
    -- enchantment owner, rather than replacing the existing timer.
    ctx:remove(player, component.PLAYER_EXHAUSTION)
    magic = ctx:get(player, component.MAGIC)
    magic.current = 10
    ctx:set(player, component.MAGIC, magic)
    apocalypse.resolve(game, player)
    harness.equal(ctx:get(foe,
        component.PARALYSIS).remaining_aut,
        first_paralysis + 80)

    -- Antimagic is conditional on a live magical spellbook. The wizard's
    -- continuing timer must use the production Enfeeble component.
    ctx:remove(player, component.PLAYER_EXHAUSTION)
    magic = ctx:get(player, component.MAGIC)
    magic.current = 10
    ctx:set(player, component.MAGIC, magic)

    local wizard = fixture.actor(ctx, monsters.MONS_ORC_WIZARD,
        13, 10, 100)

    function game:random()
        return 0
    end

    apocalypse.resolve(game, player)

    local enfeeble = ctx:get(wizard, component.MONSTER_ENFEEBLE)

    harness.truthy(enfeeble ~= nil and
        enfeeble.antimagic_aut > 0)

    -- Radius iteration is geometric rather than ECS creation order.
    -- A freed Kirke victim is good-neutral, which DCSS still includes.
    local north = fixture.actor(ctx, monsters.MONS_ORC,
        10, 9, 100)
    local south = fixture.actor(ctx, monsters.MONS_ORC,
        10, 11, 100)
    local west = fixture.actor(ctx, monsters.MONS_ORC,
        9, 10, 100)
    local east = fixture.actor(ctx, monsters.MONS_ORC,
        11, 10, 100)

    ctx:add(north, tactical.KIRKE_FREED, {
        freed = true,
        kind_id = monsters.MONS_ORC,
        original_kind_id = monsters.MONS_ORC,
    })

    local ordered = ru_power.targets(game, player)
    local by_entity = {}

    for index, target in ipairs(ordered) do
        by_entity[target.entity] = index
    end

    harness.truthy(by_entity[north] ~= nil)
    harness.truthy(by_entity[east] < by_entity[west])
    harness.truthy(by_entity[west] < by_entity[south])
    harness.truthy(by_entity[south] < by_entity[north])
end

return test
