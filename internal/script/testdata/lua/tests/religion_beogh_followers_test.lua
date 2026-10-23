-- Beogh companions are persistent god gifts, not band links. These cases
-- exercise conversion, deathbed rescue, desertion, and wrath through the
-- same ECS allegiance and damage owners used by the playable game.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local gods = require("constants.gods")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local beogh = require("policy.religion.gods.beogh")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local health = require("policy.combat.monster_health")
local targets = require("policy.ai.targets")
local worship = require("policy.religion.worship")
local wrath = require("policy.religion.wrath.beogh")

local test = {}

-- Source Beogh conversion requires an orc worshipper with three stars. A
-- living companion retains its god provenance when its side later changes.
local function follower_case(ctx, x)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, x, 10, 40)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HILL_ORC,
        job_id = jobs.JOB_FIGHTER,
        name = "Orc convert",
    })
    ctx:add(player, component.PROGRESSION, { level = 10 })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.BEOGH,
        piety = 100,
        penance = {},
    })

    local owner = fixture.context(ctx, player)
    local conversion_draws = 0

    function owner:random(stream, bound)
        if stream == streams.RELIGION then
            conversion_draws = conversion_draws + 1

            if conversion_draws <= 2 then
                return bound - 1
            end

            return 0
        end

        return ctx:random(stream, bound)
    end

    return owner, player
end

-- Sight conversion writes a saved god-gift identity and changes combat
-- allegiance without touching the monster's band leader relation.
local function sight_and_desertion(ctx)
    local owner, player = follower_case(ctx, 10)
    local orc = fixture.actor(ctx, monsters.MONS_ORC_KNIGHT, 11, 10)

    harness.truthy(beogh.convert_on_turn(owner, player, orc))
    harness.equal(targets.real_attitude(owner, orc), attitudes.FRIENDLY)
    harness.truthy(ctx:get(orc, component.BEOGH_ORC).gift)
    harness.falsy(targets.enemy(owner, orc, player))

    harness.truthy(worship.renounce(owner, player))
    harness.equal(targets.real_attitude(owner, orc), attitudes.HOSTILE)
    harness.truthy(ctx:get(orc, component.BEOGH_ORC).gift)
end

-- The source deathbed path rescues a visible orc killed by its potential
-- Hill Orc messiah, restoring a fraction of maximum HP instead of a kill.
local function deathbed(ctx)
    local owner, player = follower_case(ctx, 20)
    local orc = fixture.actor(ctx, monsters.MONS_ORC_KNIGHT, 21, 10)
    local state = ctx:get(orc, component.HEALTH)

    state.current = 10
    ctx:set(orc, component.HEALTH, state)

    function owner:random(stream, bound)
        if stream == streams.RELIGION then
            return bound - 1
        end

        return ctx:random(stream, bound)
    end

    local after = health.damage(owner, orc, 20, player)

    harness.truthy(after.current > 0)
    harness.truthy(ctx:get(orc, component.BEOGH_ORC).gift)
    harness.equal(targets.real_attitude(owner, orc), attitudes.FRIENDLY)
end

-- Damage from a player can offer the same one-shot contest before the
-- monster acts; save validation rejects an impossible friendly non-gift.
local function contact_and_restore(ctx)
    local owner, player = follower_case(ctx, 40)
    local orc = fixture.actor(ctx, monsters.MONS_ORC_KNIGHT, 41, 10)

    ctx:add(orc, component.AI, { behavior = "wander" })

    health.damage(owner, orc, 1, player)

    harness.truthy(ctx:get(orc, component.BEOGH_ORC).gift)
    beogh.validate(owner, orc)

    local state = ctx:get(orc, component.BEOGH_ORC)

    state.gift = false
    ctx:set(orc, component.BEOGH_ORC, state)

    local valid = pcall(beogh.validate, owner, orc)

    harness.falsy(valid)
end

-- A follower's lethal hit can also rescue an orc, but the source gives it
-- a separate one-in-three failure before testing the player's piety and XL.
local function follower_deathbed(ctx)
    local owner, player = follower_case(ctx, 50)
    local follower = fixture.actor(ctx, monsters.MONS_ORC_KNIGHT,
        51, 10)
    local orc = fixture.actor(ctx, monsters.MONS_ORC_KNIGHT, 52, 10)

    harness.truthy(beogh.convert_on_turn(owner, player, follower))

    local state = ctx:get(orc, component.HEALTH)

    state.current = 10
    ctx:set(orc, component.HEALTH, state)

    function owner:random(stream, bound)
        if stream == streams.RELIGION then
            return bound - 1
        end

        return ctx:random(stream, bound)
    end

    local after = health.damage(owner, orc, 20, follower)

    harness.truthy(after.current > 0)
    harness.truthy(ctx:get(orc, component.BEOGH_ORC).gift)
end

-- Under Beogh penance, nearby alert gifts make the source saving throw.
-- A failed save changes their saved real side before the wrath ends.
local function wrath_abandonment(ctx)
    local owner, player = follower_case(ctx, 30)
    local orc = fixture.actor(ctx, monsters.MONS_ORC_KNIGHT, 31, 10)

    harness.truthy(beogh.convert_on_turn(owner, player, orc))

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    state.penance[gods.BEOGH] = 10
    ctx:set(player, component.RELIGION_WORSHIP, state)

    local card_draws = 0

    function owner:random(stream, bound)
        if stream == streams.CARDS then
            if bound == 8 then
                card_draws = card_draws + 1
                return 3
            end

            return 0
        end

        if stream == streams.RELIGION then
            return 0
        end

        return ctx:random(stream, bound)
    end

    harness.truthy(wrath.apply(owner, player))
    harness.equal(card_draws, 1)
    harness.equal(targets.real_attitude(owner, orc), attitudes.HOSTILE)
    harness.truthy(ctx:get(orc, component.BEOGH_ORC).gift)
end

-- One test transaction can inspect all persisted component transitions;
-- each helper uses independent actors so the prior case cannot steer RNG.
function test.run(ctx)
    sight_and_desertion(ctx)
    deathbed(ctx)
    contact_and_restore(ctx)
    follower_deathbed(ctx)
    wrath_abandonment(ctx)
end

return test
