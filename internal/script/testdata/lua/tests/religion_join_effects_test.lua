-- Joining and leaving gods must change live actor state, not only the
-- player's worship record. These fixtures use production component schemas.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local fixture = require("tests.monster_ally_support_fixture")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local sources = require("constants.religion_sources")
local species = require("ids.species")
local targets = require("policy.ai.targets")
local decision = require("systems.monster_decision")
local worship = require("policy.religion.worship")

local test = {}

-- A real worship component and position let source join effects address the
-- active level without inventing a second player state for the fixture.
local function player(ctx)
    local entity = ctx:create()

    ctx:add(entity, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Join effects test",
    })
    ctx:add(entity, component.RELIGION_WORSHIP, {})
    ctx:add(entity, component.WALLET, {})
    ctx:add(entity, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })

    return entity
end

-- Source plant nature comes from the monster catalog. Give the actor a
-- position so joining Fedhas can distinguish the current floor.
local function monster(ctx, kind_id, level_id)
    local entity = ctx:create()

    ctx:add(entity, component.ACTOR, {
        kind_id = kind_id,
    })
    ctx:add(entity, component.POSITION, {
        level_id = level_id,
        x = 2,
        y = 1,
    })

    return entity
end

-- Fedhas converts eligible hostile plants on their turns, excludes
-- snaplasher vines, and makes every plant hostile after desertion.
local function fedhas_allegiance(ctx)
    local fedhas = require("policy.religion.gods.fedhas")
    local actor = player(ctx)
    local game = fixture.context(ctx, actor)
    local plant = monster(ctx, monsters.MONS_PLANT, 1)
    local remote = monster(ctx, monsters.MONS_FUNGUS, 2)
    local vine = monster(ctx, monsters.MONS_SNAPLASHER_VINE, 1)

    ctx:add(plant, component.HEALTH, {
        current = 10,
        max = 10,
    })
    ctx:add(plant, component.AI, {
        behavior = "wander",
    })

    harness.equal(targets.real_attitude(game, plant), attitudes.HOSTILE)

    worship.join(game, actor, gods.FEDHAS, sources.ALTAR)

    harness.equal(targets.real_attitude(game, plant), attitudes.HOSTILE)
    decision.update(game, plant)

    harness.truthy(fedhas.neutralise(game, actor, remote))
    harness.equal(targets.real_attitude(game, plant),
        attitudes.GOOD_NEUTRAL)
    harness.equal(targets.real_attitude(game, remote),
        attitudes.GOOD_NEUTRAL)
    harness.equal(fedhas.neutralise(game, actor, vine), false)
    harness.equal(targets.real_attitude(game, vine), attitudes.HOSTILE)

    -- Desertion also breaks temporary charm, which otherwise masks the
    -- source hostility and leaves the plant fighting for the player.
    ctx:add(plant, component.MONSTER_ALLEGIANCE, {
        charm_aut = 40,
    })

    worship.renounce(game, actor)

    harness.equal(targets.real_attitude(game, plant), attitudes.HOSTILE)
    harness.equal(targets.attitude(game, plant), attitudes.HOSTILE)
    harness.falsy(ctx:has(plant, component.MONSTER_ALLEGIANCE))
    harness.equal(targets.real_attitude(game, remote), attitudes.HOSTILE)
    harness.equal(targets.real_attitude(game, vine), attitudes.HOSTILE)

    worship.join(game, actor, gods.FEDHAS, sources.ALTAR)

    harness.truthy(fedhas.neutralise(game, actor, plant))
    harness.equal(targets.real_attitude(game, plant),
        attitudes.GOOD_NEUTRAL)

    local stranger = monster(ctx, monsters.MONS_GOBLIN, 1)

    ctx:add(stranger, component.FEDHAS_PLANT, {
        attitude = attitudes.GOOD_NEUTRAL,
        attempted = true,
    })

    harness.truthy(pcall(fedhas.validate, game, plant))
    harness.falsy(pcall(fedhas.validate, game, stranger),
        "saved Fedhas allegiance must belong to a plant")
end

-- A new Fedhas worshipper ends a hostile awakened forest on this floor,
-- leaving an unrelated floor's timer untouched.
local function fedhas_forest(ctx)
    local actor = player(ctx)
    local game = fixture.context(ctx, actor)
    local local_caster = monster(ctx, monsters.MONS_SPRIGGAN_DRUID, 1)
    local remote_caster = monster(ctx, monsters.MONS_SPRIGGAN_DRUID, 2)

    ctx:add(local_caster, component.MONSTER_AWAKE_FOREST, {
        remaining_aut = 80,
    })
    ctx:add(remote_caster, component.MONSTER_AWAKE_FOREST, {
        remaining_aut = 80,
    })

    worship.join(game, actor, gods.FEDHAS, sources.ALTAR)

    harness.equal(ctx:has(local_caster, component.MONSTER_AWAKE_FOREST),
        false)
    harness.truthy(ctx:has(remote_caster, component.MONSTER_AWAKE_FOREST))
end

-- Okawaru dismisses only friendly summons owned by the joining player on
-- the current floor; hostile, other-owner, and remote summons remain.
local function okawaru_summons(ctx)
    local actor = player(ctx)
    local game = fixture.context(ctx, actor)
    local other = player(ctx)
    local friendly = monster(ctx, monsters.MONS_RAT, 1)
    local hostile = monster(ctx, monsters.MONS_RAT, 1)
    local remote = monster(ctx, monsters.MONS_RAT, 2)
    local foreign = monster(ctx, monsters.MONS_RAT, 1)
    local charmed = monster(ctx, monsters.MONS_RAT, 1)
    local deserted = monster(ctx, monsters.MONS_PLANT, 1)

    ctx:add(friendly, component.SUMMON, {
        owner = actor,
        attitude = attitudes.FRIENDLY,
    })
    ctx:add(hostile, component.SUMMON, {
        owner = actor,
        attitude = attitudes.HOSTILE,
    })
    ctx:add(remote, component.SUMMON, {
        owner = actor,
        attitude = attitudes.FRIENDLY,
    })
    ctx:add(foreign, component.SUMMON, {
        owner = other,
        attitude = attitudes.FRIENDLY,
    })
    ctx:add(charmed, component.SUMMON, {
        owner = actor,
        attitude = attitudes.HOSTILE,
    })
    ctx:add(charmed, component.MONSTER_ALLEGIANCE, {
        charm_aut = 40,
    })
    ctx:add(deserted, component.SUMMON, {
        owner = actor,
        attitude = attitudes.FRIENDLY,
    })
    ctx:add(deserted, component.FEDHAS_PLANT, {
        attitude = attitudes.HOSTILE,
        attempted = false,
    })

    worship.join(game, actor, gods.OKAWARU, sources.ALTAR)

    harness.equal(ctx:has(friendly, component.ACTOR), false)
    harness.equal(ctx:has(charmed, component.ACTOR), false)
    harness.truthy(ctx:has(hostile, component.ACTOR))
    harness.truthy(ctx:has(remote, component.ACTOR))
    harness.truthy(ctx:has(foreign, component.ACTOR))
    harness.truthy(ctx:has(deserted, component.ACTOR))
end

-- Run each transition in one script while keeping its actor setup separate.
function test.run(ctx)
    fedhas_allegiance(ctx)
    fedhas_forest(ctx)
    okawaru_summons(ctx)
end

return test
