
local catalog = require("policy.catalog")
local component = require("constants.component")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local species = require("ids.species")
local spells = require("ids.spells")
local magic = require("policy.character.demonic_magic")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

-- Seed demonic magic attacker and target independently before the reaction mutates either.
local function fixture(ctx)
    local player = ctx:create()
    local rat = ctx:create()
    local no_threat = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Demonic Magic",
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })
    ctx:add(rat, component.ACTOR, {
        kind_id = monsters.MONS_RAT,
        speed = 10,
    })
    ctx:add(rat, component.HEALTH, {
        current = 10,
        max = 10,
    })
    ctx:add(rat, component.POSITION, {
        level_id = 1,
        x = 3,
        y = 1,
    })
    ctx:add(no_threat, component.ACTOR, {
        kind_id = monsters.MONS_BALL_LIGHTNING,
        speed = 10,
    })
    ctx:add(no_threat, component.HEALTH, {
        current = 10,
        max = 10,
    })
    ctx:add(no_threat, component.POSITION, {
        level_id = 1,
        x = 2,
        y = 1,
    })

    return player, rat, no_threat
end

-- Proxy spell draws while leaving the player and hostile rat in the live ECS.
local function predictable(ctx, player)
    local world = setmetatable({}, { __index = ctx })

    -- Bind policy ownership to demonic magic fixture actor so player-only branches execute on that entity.
    function world.player()
        return player
    end

    -- Use the highest spell draw to test Demonic Magic range gating.
    function world.random(_, stream, bound)
        harness.equal(stream, "spell", "Demonic Magic uses spell RNG")

        return bound - 1
    end

    -- Make demonic magic sight deterministic while leaving actor positions to the ECS fixture.
    function world.visible()
        return true
    end

    return world
end

-- One Demonic Magic level does not reach a rat two cells away.
function test.run(ctx)
    local player, rat, no_threat = fixture(ctx)
    local world = predictable(ctx, player)
    local spell = catalog.get("spells", spells.SPELL_SWIFTNESS)

    magic.on_success(world, player, spell)
    harness.falsy(ctx:has(rat, component.PARALYSIS),
        "ordinary casters do not trigger Demonic Magic")

    records.grant_acquired(ctx, player, mutations.MUT_DEMONIC_MAGIC, 1)
    magic.on_success(world, player, spell)
    -- Rank controls the target radius before any paralysis roll.
    harness.falsy(ctx:has(rat, component.PARALYSIS),
        "one Demonic Magic level does not reach a rat two cells away")

    records.grant_acquired(ctx, player, mutations.MUT_DEMONIC_MAGIC, 1)
    magic.on_success(world, player, spell)
    harness.equal(ctx:get(rat, component.PARALYSIS).remaining_aut, 50,
        "two Demonic Magic levels paralyze a susceptible nearby rat")
    -- Nearby harmless actors must not spend the spell-triggered paralysis chance.
    harness.falsy(ctx:has(no_threat, component.PARALYSIS),
        "nonthreatening monsters are excluded from Demonic Magic")
end

return test
