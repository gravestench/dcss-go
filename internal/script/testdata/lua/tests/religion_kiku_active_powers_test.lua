-- Kiku's two ordinary powers share live worship gating, but their effects
-- differ: Torment uses the common area owner, while wretches are real bodies.
local abilities = require("ids.abilities")
local area = require("policy.combat.torment_area")
local attitudes = require("constants.attitude")
local branches = require("ids.branches")
local catalog = require("policy.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local death = require("policy.death")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local monster_threat = require("policy.combat.monster_threat")
local monster_willpower = require("policy.combat.monster_willpower")
local threat_bands = require("constants.monster_threat")
local piety = require("policy.religion.piety")
local registry = require("policy.abilities.registry")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local torment_sources = require("constants.torment_sources")
local targets = require("policy.ai.targets")
local wretches = require("policy.religion.kikubaaqudgha.wretches")

local test = {}

-- Build only production components: the shared cost owner reads these exact
-- IDs, and the registry checks the same state as the game menu.
local function worshipper(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Kiku tester",
    })
    ctx:add(player, component.SKILLS, { entries = {} })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })
    ctx:add(player, component.MAGIC, {
        current = 10,
        max = 10,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.KIKUBAAQUDGHA,
        piety = piety.breakpoint(1),
        penance = {},
    })

    return player
end

-- Availability must track the two source rank thresholds, current MP, and
-- a live patron. A saved menu option cannot outlive a conversion to Trog.
local function ability_gates(ctx, player)
    local unearth = registry.get(abilities.KIKU_UNEARTH_WRETCHES)
    local torment = registry.get(abilities.KIKU_TORMENT)

    harness.truthy(unearth.available(ctx, player))
    harness.falsy(torment.available(ctx, player))
    harness.equal(unearth.prepare(ctx, player), nil)

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.piety = piety.breakpoint(5)
    ctx:set(player, component.RELIGION_WORSHIP, worship)
    harness.truthy(torment.available(ctx, player))

    local magic = ctx:get(player, component.MAGIC)

    magic.current = 2
    ctx:set(player, component.MAGIC, magic)
    harness.equal(unearth.prepare(ctx, player),
        "You do not have enough magic.")
    harness.equal(torment.prepare(ctx, player),
        "You do not have enough magic.")

    worship.god_id = gods.TROG
    ctx:set(player, component.RELIGION_WORSHIP, worship)
    harness.falsy(unearth.available(ctx, player))
    harness.falsy(torment.available(ctx, player))
end

-- The invocation delegates geometry and HP loss to the existing area
-- policy, but must pass the Kiku-specific source for self protection.
local function torment_source(ctx, player)
    local original_area = area.apply
    local original_failed = costs.failed
    local original_spend = costs.spend
    local original_piety = costs.piety_cost
    local observed = {}
    local proxy = setmetatable({}, { __index = ctx })

    function proxy:emit(channel, message)
        observed.message = message
        observed.channel = channel
    end

    area.apply = function(_, caster, channel, position, source)
        observed.caster = caster
        observed.area_channel = channel
        observed.position = position
        observed.source = source
    end

    costs.failed = function(_, _, base, scale, divisor)
        harness.equal(base, 60)
        harness.equal(scale, 5)
        harness.equal(divisor, 20)

        return false
    end

    costs.piety_cost = function(_, base)
        harness.equal(base, 8)

        return 8
    end

    costs.spend = function(_, caster, mp, points)
        observed.spent = { caster, mp, points }
    end

    registry.get(abilities.KIKU_TORMENT).resolve(proxy, player)
    area.apply = original_area
    costs.failed = original_failed
    costs.spend = original_spend
    costs.piety_cost = original_piety

    harness.equal(observed.caster, player)
    harness.equal(observed.area_channel, channels.RELIGION)
    harness.equal(observed.source, torment_sources.KIKU_INVOKED)
    harness.equal(observed.spent[2], 4)
    harness.equal(observed.spent[3], 8)
end

-- Successful divine invocation pays its cost even when placement finds no
-- open tile. The source message explains the result instead of refunding MP.
local function no_wretch_space(ctx, player)
    local original_invoke = wretches.invoke
    local original_failed = costs.failed
    local original_spend = costs.spend
    local original_piety = costs.piety_cost
    local observed = {}
    local proxy = setmetatable({}, { __index = ctx })

    function proxy:emit(channel, message)
        observed.channel = channel
        observed.message = message
    end

    wretches.invoke = function()
        return 0
    end

    costs.failed = function(_, _, base, scale, divisor)
        harness.equal(base, 40)
        harness.equal(scale, 5)
        harness.equal(divisor, 20)

        return false
    end

    costs.piety_cost = function(_, base)
        harness.equal(base, 4)

        return 4
    end

    costs.spend = function(_, _, mp, points)
        observed.mp = mp
        observed.piety = points
    end

    registry.get(abilities.KIKU_UNEARTH_WRETCHES).resolve(proxy, player)
    wretches.invoke = original_invoke
    costs.failed = original_failed
    costs.spend = original_spend
    costs.piety_cost = original_piety

    harness.equal(observed.channel, channels.RELIGION)
    harness.truthy(observed.message:find("no space", 1, true))
    harness.equal(observed.mp, 3)
    harness.equal(observed.piety, 4)
end

-- An untrained invoker still calls exactly two bodies. An expired marker
-- sets one-HP fodder to zero so the ordinary death phase can create a corpse.
local function wretch_lifecycle(ctx, player)
    local game = fixture.context(ctx, player)

    function game:random(stream, bound)
        harness.equal(stream, streams.RELIGION)
        harness.truthy(bound > 0)

        return 0
    end

    harness.equal(wretches.count(game, player), 2)

    -- Temple has no native corpse population. The source fallback must
    -- still choose a real body from other effective branch definitions.
    function game:level_branch()
        return branches.BRANCH_TEMPLE
    end

    local kind_id = wretches.kind(game, player)
    local definition = catalog.get("monsters", kind_id)
    local source_species = catalog.get("monsters",
        definition.species_id or definition.id)

    harness.truthy(source_species.leaves_corpse)

    local creature = fixture.actor(ctx, monsters.MONS_RAT, 4, 4, 1)

    ctx:add(creature, component.RELIGION_KIKU_WRETCH, {
        remaining_aut = 20,
    })
    ctx:add(creature, component.PARALYSIS, {
        remaining_aut = 9999,
    })

    local ally = fixture.actor(ctx, monsters.MONS_QUOKKA, 5, 4, 10)

    ctx:add(ally, component.SUMMON, {
        owner = player,
        attitude = attitudes.FRIENDLY,
    })

    harness.falsy(targets.enemy(game, ally, creature))
    harness.truthy(targets.enemy(game, player, creature))
    harness.equal(monster_threat.monster(game, player, creature,
        catalog.get("monsters", monsters.MONS_RAT)),
        threat_bands.TRIVIAL)
    harness.equal(monster_willpower.level(game, creature,
        catalog.get("monsters", monsters.MONS_RAT)), 0)

    wretches.tick(game, creature, 10)
    harness.equal(ctx:get(creature,
        component.RELIGION_KIKU_WRETCH).remaining_aut, 10)
    harness.equal(ctx:get(creature, component.HEALTH).current, 1)

    wretches.tick(game, creature, 10)
    harness.equal(ctx:get(creature, component.HEALTH).current, 0)

    -- A forced losing corpse roll cannot erase a Kiku wretch's body.
    function game:random(stream, bound)
        harness.equal(stream, streams.CORPSE)
        harness.equal(bound, 255)

        return 1
    end

    definition = catalog.get("monsters", monsters.MONS_RAT)
    local position = ctx:get(creature, component.POSITION)
    local corpse = death.corpse(game, definition, position, nil, creature)

    harness.truthy(corpse)
    harness.equal(ctx:get(corpse, component.CORPSE).monster_id,
        monsters.MONS_RAT)
end

-- Run each independent assertion against one real ECS world. The routine
-- does not redeclare a component schema or a fake monster catalog.
function test.run(ctx)
    local player = worshipper(ctx)
    local game = fixture.context(ctx, player)

    ability_gates(game, player)
    torment_source(game, player)
    no_wretch_space(game, player)
    wretch_lifecycle(ctx, player)
end

return test
