-- Jiyva changes a monster's saved allegiance only when that monster gets
-- its next action. These fixtures use the production catalog and schemas.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local fixture = require("tests.monster_ally_support_fixture")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local piety = require("policy.religion.piety")
local sources = require("constants.religion_sources")
local species = require("ids.species")
local targets = require("policy.ai.targets")
local jiyva = require("policy.religion.gods.jiyva")
local worship = require("policy.religion.worship")

local test = {}

-- The real worship component makes conversion depend on the currently
-- selected god, including after a later renunciation.
local function player(ctx)
    local entity = ctx:create()

    ctx:add(entity, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Slime allegiance test",
    })
    ctx:add(entity, component.RELIGION_WORSHIP, {})
    ctx:add(entity, component.WALLET, {})
    ctx:add(entity, component.ATTRIBUTES, {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(entity, component.SKILLS, {
        entries = {},
    })
    ctx:add(entity, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })

    return entity
end

-- Monster genus comes from the imported source catalog, not a test copy.
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
    ctx:add(entity, component.HEALTH, {
        current = 10,
        max = 10,
    })
    ctx:add(entity, component.AI, {
        behavior = "wander",
        bat_retreat_actions = 0,
    })

    return entity
end

-- Source slime genera include jellies and two eye families. A converted
-- monster stays good-neutral until Jiyva is abandoned, even off-level.
local function conversion_and_desertion(ctx)
    local actor = player(ctx)
    local game = fixture.context(ctx, actor)
    local jelly = monster(ctx, monsters.MONS_JELLY, 1)
    local eye = monster(ctx, monsters.MONS_FLOATING_EYE, 1)
    local brain = monster(ctx, monsters.MONS_GLOWING_ORANGE_BRAIN, 1)
    local remote = monster(ctx, monsters.MONS_JELLY, 2)
    local goblin = monster(ctx, monsters.MONS_GOBLIN, 1)
    local natural_neutral = monster(ctx, monsters.MONS_JELLY, 1)

    ctx:add(natural_neutral, component.SUMMON, {
        owner = actor,
        attitude = attitudes.GOOD_NEUTRAL,
    })

    worship.join(game, actor, gods.JIYVA, sources.ALTAR)

    harness.truthy(jiyva.neutralise(game, actor, jelly))
    harness.truthy(jiyva.neutralise(game, actor, eye))
    harness.truthy(jiyva.neutralise(game, actor, brain))
    harness.truthy(jiyva.neutralise(game, actor, remote))
    harness.falsy(jiyva.neutralise(game, actor, goblin))
    harness.falsy(jiyva.neutralise(game, actor, natural_neutral))

    harness.equal(targets.real_attitude(game, jelly),
        attitudes.GOOD_NEUTRAL)
    harness.equal(targets.real_attitude(game, eye),
        attitudes.GOOD_NEUTRAL)
    harness.equal(targets.real_attitude(game, brain),
        attitudes.GOOD_NEUTRAL)
    harness.equal(targets.real_attitude(game, remote),
        attitudes.GOOD_NEUTRAL)
    harness.equal(targets.real_attitude(game, goblin), attitudes.HOSTILE)

    -- Source DACT_ALLY_SLIME also breaks charm before making a former
    -- fellow slime hostile again.
    ctx:add(jelly, component.MONSTER_ALLEGIANCE, {
        charm_aut = 40,
    })

    worship.renounce(game, actor)

    harness.equal(targets.attitude(game, jelly), attitudes.HOSTILE)
    harness.equal(targets.real_attitude(game, eye), attitudes.HOSTILE)
    harness.equal(targets.real_attitude(game, brain), attitudes.HOSTILE)
    harness.equal(targets.real_attitude(game, remote), attitudes.HOSTILE)
    harness.equal(targets.real_attitude(game, natural_neutral),
        attitudes.GOOD_NEUTRAL)
    harness.falsy(ctx:has(jelly, component.MONSTER_ALLEGIANCE))
end

-- Penance consumes one attempt without making the slime neutral. The
-- exact payment that clears penance lets that same actor try again.
local function penance_retry(ctx)
    local actor = player(ctx)
    local game = fixture.context(ctx, actor)
    local slime = monster(ctx, monsters.MONS_SLIME_CREATURE, 1)

    worship.join(game, actor, gods.JIYVA, sources.ALTAR)

    local state = ctx:get(actor, component.RELIGION_WORSHIP)

    state.penance[gods.JIYVA] = 2
    ctx:set(actor, component.RELIGION_WORSHIP, state)

    harness.falsy(jiyva.neutralise(game, actor, slime))
    harness.equal(targets.real_attitude(game, slime), attitudes.HOSTILE)
    harness.truthy(ctx:get(slime, component.JIYVA_SLIME).attempted)
    harness.falsy(jiyva.neutralise(game, actor, slime))

    piety.gain(game, actor, 2, 1, false)

    harness.equal(ctx:get(actor,
        component.RELIGION_WORSHIP).penance[gods.JIYVA], 0)
    harness.falsy(ctx:get(slime, component.JIYVA_SLIME).attempted)

    -- Charm is a current friendly side, so it prevents conversion even
    -- though the monster's real allegiance remains hostile.
    ctx:add(slime, component.MONSTER_ALLEGIANCE, {
        charm_aut = 30,
    })

    harness.falsy(jiyva.neutralise(game, actor, slime))
    ctx:remove(slime, component.MONSTER_ALLEGIANCE)

    harness.truthy(jiyva.neutralise(game, actor, slime))
    harness.equal(targets.real_attitude(game, slime),
        attitudes.GOOD_NEUTRAL)
end

-- Save validation refuses a forged slime-side tag on an unrelated monster
-- or an entity with no monster actor; a converted jelly remains valid.
local function saved_allegiance(ctx)
    local actor = player(ctx)
    local game = fixture.context(ctx, actor)
    local slime = monster(ctx, monsters.MONS_JELLY, 1)
    local goblin = monster(ctx, monsters.MONS_GOBLIN, 1)
    local orphan = ctx:create()

    worship.join(game, actor, gods.JIYVA, sources.ALTAR)
    jiyva.neutralise(game, actor, slime)

    ctx:add(goblin, component.JIYVA_SLIME, {
        attitude = attitudes.GOOD_NEUTRAL,
        attempted = true,
    })
    ctx:add(orphan, component.JIYVA_SLIME, {
        attitude = attitudes.HOSTILE,
        attempted = true,
    })

    harness.truthy(pcall(jiyva.validate, game, slime))
    harness.falsy(pcall(jiyva.validate, game, goblin))
    harness.falsy(pcall(jiyva.validate, game, orphan))
end

-- Source mons_att_changed dismisses only this slime's summons whose real
-- side differs after a conversion or desertion. Dissolution is a source
-- jelly that can summon eyeballs, so this has an actual spellbook user.
local function owned_summons_follow_side(ctx)
    local actor = player(ctx)
    local game = fixture.context(ctx, actor)
    local dissolution = monster(ctx, monsters.MONS_DISSOLUTION, 1)
    local hostile_eye = monster(ctx, monsters.MONS_FLOATING_EYE, 1)
    local neutral_eye = monster(ctx, monsters.MONS_FLOATING_EYE, 1)
    local spoken = {}

    function game:emit(_, message)
        spoken[#spoken + 1] = message
    end

    ctx:add(hostile_eye, component.SUMMON, {
        owner = dissolution,
        source_id = spells.SPELL_SUMMON_EYEBALLS,
        attitude = attitudes.HOSTILE,
        expires_aut = 500,
    })
    ctx:add(neutral_eye, component.SUMMON, {
        owner = dissolution,
        source_id = spells.SPELL_SUMMON_EYEBALLS,
        attitude = attitudes.GOOD_NEUTRAL,
        expires_aut = 500,
    })

    worship.join(game, actor, gods.JIYVA, sources.ALTAR)
    jiyva.neutralise(game, actor, dissolution)

    harness.falsy(ctx:has(hostile_eye, component.ACTOR),
        "Dissolution's hostile summons must leave when it converts")
    harness.truthy(ctx:has(neutral_eye, component.ACTOR))
    harness.equal(spoken[#spoken], "Dissolution trembles before you.")

    local allied_eye = monster(ctx, monsters.MONS_FLOATING_EYE, 1)
    local hostile_survivor = monster(ctx, monsters.MONS_FLOATING_EYE, 1)

    ctx:add(allied_eye, component.SUMMON, {
        owner = dissolution,
        source_id = spells.SPELL_SUMMON_EYEBALLS,
        attitude = attitudes.GOOD_NEUTRAL,
        expires_aut = 500,
    })
    ctx:add(hostile_survivor, component.SUMMON, {
        owner = dissolution,
        source_id = spells.SPELL_SUMMON_EYEBALLS,
        attitude = attitudes.HOSTILE,
        expires_aut = 500,
    })

    worship.renounce(game, actor)

    harness.falsy(ctx:has(neutral_eye, component.ACTOR),
        "Dissolution's neutral summons must leave on desertion")
    harness.falsy(ctx:has(allied_eye, component.ACTOR))
    harness.truthy(ctx:has(hostile_survivor, component.ACTOR))
end

-- Keep the first source transition as one observable game operation.
function test.run(ctx)
    conversion_and_desertion(ctx)
    penance_retry(ctx)
    saved_allegiance(ctx)
    owned_summons_follow_side(ctx)
end

return test
