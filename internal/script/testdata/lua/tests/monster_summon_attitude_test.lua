local allies = require("policy.character.allies")
local attitude = require("constants.attitude")
local catalog = require("policy.catalog")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local save_summons = require("policy.save.summons")
local spells = require("ids.spells")
local targets = require("policy.ai.targets")

local test = {}

-- Source monster allegiance distinguishes real attitude from temporary
-- charm. Summons keep a real attitude even when their caster later changes.
local function real_and_temporary_attitudes(ctx, game)
    local hostile = fixture.actor(ctx, monsters.MONS_RAT, 10, 10)
    local friendly = fixture.actor(ctx, monsters.MONS_RAT, 11, 10)
    local neutral = fixture.actor(ctx, monsters.MONS_RAT, 12, 10)
    local good_neutral = fixture.actor(ctx, monsters.MONS_RAT, 13, 10)

    ctx:add(friendly, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitude.FRIENDLY,
    })
    ctx:add(neutral, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitude.NEUTRAL,
    })
    ctx:add(good_neutral, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitude.GOOD_NEUTRAL,
    })

    harness.equal(targets.real_attitude(game, hostile), attitude.HOSTILE,
        "ordinary monsters are hostile")
    harness.equal(targets.real_attitude(game, friendly), attitude.FRIENDLY,
        "authored friendly attitude is durable")
    harness.equal(targets.real_attitude(game, neutral), attitude.NEUTRAL,
        "authored neutral attitude stays distinct")
    harness.equal(targets.real_attitude(game, good_neutral),
        attitude.GOOD_NEUTRAL,
        "good-neutral is not collapsed into friendly")

    ctx:add(hostile, component.MONSTER_ALLEGIANCE, {
        charm_aut = 30,
    })

    harness.equal(targets.attitude(game, hostile), attitude.FRIENDLY,
        "charm changes the temporary attitude")
    harness.equal(targets.real_attitude(game, hostile), attitude.HOSTILE,
        "charm does not rewrite real attitude")
end

-- Source SAME_ATTITUDE copies a monster caster's current side. No Love
-- remains a player-only exception for newly created ordinary allies.
local function creation_attitude(ctx, game, player)
    local hostile = fixture.actor(ctx, monsters.MONS_ORC_PRIEST, 20, 20)
    local friendly = fixture.actor(ctx, monsters.MONS_ORC_PRIEST, 21, 20)
    local neutral = fixture.actor(ctx, monsters.MONS_ORC_PRIEST, 22, 20)
    local rat = catalog.get("monsters", monsters.MONS_RAT)
    local foxfire = catalog.get("monsters", monsters.MONS_FOXFIRE)

    ctx:add(friendly, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitude.FRIENDLY,
    })
    ctx:add(neutral, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitude.NEUTRAL,
    })

    harness.equal(allies.summoned_attitude(game, hostile, rat),
        attitude.HOSTILE, "hostile caster creates a hostile summon")
    harness.equal(allies.summoned_attitude(game, friendly, rat),
        attitude.FRIENDLY, "friendly caster creates a friendly summon")
    harness.equal(allies.summoned_attitude(game, neutral, rat),
        attitude.NEUTRAL, "neutral caster creates a neutral summon")
    harness.equal(allies.summoned_attitude(game, player, rat),
        attitude.FRIENDLY, "ordinary player summons a friendly ally")

    records.grant_acquired(ctx, player, mutations.MUT_NO_LOVE, 1)

    harness.equal(allies.summoned_attitude(game, player, rat),
        attitude.HOSTILE, "No Love rejects an ordinary new ally")
    harness.equal(allies.summoned_attitude(game, player, foxfire),
        attitude.FRIENDLY, "No Love exempts a conjured creature")
end

-- A summon record stores attitude as a named field so its restored side
-- does not depend on who owns the active turn or on vault overrides.
local function saved_attitude(ctx, game)
    local owner = fixture.actor(ctx, monsters.MONS_ORC_PRIEST, 30, 30)
    local summon = fixture.actor(ctx, monsters.MONS_RAT, 31, 30)

    ctx:add(summon, component.SUMMON, {
        owner = owner,
        source_id = spells.SPELL_SUMMON_SMALL_MAMMAL,
        expires_aut = 100,
        attitude = attitude.GOOD_NEUTRAL,
    })

    local state = ctx:get(summon, component.SUMMON)

    harness.equal(state.attitude, attitude.GOOD_NEUTRAL,
        "summon record preserves good-neutral attitude")
    harness.equal(targets.real_attitude(game, summon),
        attitude.GOOD_NEUTRAL,
        "targeting reads the saved summon attitude")

    ctx:add(summon, component.AI, {
        behavior = "wander",
        memory_until_aut = 0,
        target_x = 0,
        target_y = 0,
    })

    local actor = ctx:get(summon, component.ACTOR)
    local position = ctx:get(summon, component.POSITION)
    local ai = ctx:get(summon, component.AI)

    save_summons.validate(game, summon, actor, position, ai, state, 0)
end

-- All three checks use the production component schemas and mutation rule.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 3, 3)
    local game = fixture.context(ctx, player)

    harness.truthy(type(targets.real_attitude) == "function",
        "real attitude policy is available")

    real_and_temporary_attitudes(ctx, game)
    creation_attitude(ctx, game, player)
    saved_attitude(ctx, game)
end

return test
