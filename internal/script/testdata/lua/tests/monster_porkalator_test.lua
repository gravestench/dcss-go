local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local effects = require("policy.combat.monster_spells")
local pork = require("policy.combat.monster_hexes.porkalator")
local death_hooks = require("policy.combat.death_hooks")
local catalog = require("policy.catalog")
local tactical = require("constants.monster_tactical")
local bands = require("policy.population.bands")
local links = require("policy.save.links")
local targets = require("policy.ai.targets")
local attitudes = require("constants.attitude")
local form_ids = require("constants.form_ids")
local forms = require("policy.magic.effects.forms.player")
local jobs = require("ids.jobs")
local species = require("ids.species")

local test = {}

-- Hexes pick holiness-matched hog forms and keep each prior monster body.
local function spell_hogs(ctx)
    local caster = fixture.actor(ctx, monsters.MONS_KIRKE, 8, 8)
    local target = fixture.actor(ctx, monsters.MONS_ORC, 9, 8, 50)
    local game = fixture.context(ctx, target)
    local effect = effects.effect(spells.SPELL_PORKALATOR)
    local summoner = fixture.actor(ctx, monsters.MONS_ORC, 12, 10)

    harness.truthy(effect.plan(game, caster, target),
        "Kirke can target a natural monster")
    harness.truthy(pork.viable(game, caster, target),
        "natural monster is porkalator-eligible")
    ctx:add(target, component.SUMMON, {
        owner = summoner,
        source_id = spells.SPELL_PORKALATOR,
        expires_aut = 100,
        attitude = attitudes.HOSTILE,
    })
    pork.apply(game, caster, target, { cap = 100 })
    harness.equal(ctx:get(target, component.ACTOR).kind_id,
        monsters.MONS_HOG, "natural monster becomes a hog")
    harness.equal(ctx:get(target, component.MONSTER_POLYMORPH)
        .original_kind_id, monsters.MONS_ORC,
        "pig transformation preserves original kind for reversion")
    harness.falsy(pork.viable(game, caster, target),
        "hog cannot be porkalated again")

    local demon = fixture.actor(ctx, monsters.MONS_APOCALYPSE_CRAB,
        10, 8, 50)
    local holy = fixture.actor(ctx, monsters.MONS_ANGEL, 11, 8, 50)

    pork.apply(game, caster, demon, { cap = 100 })
    pork.apply(game, caster, holy, { cap = 100 })
    harness.equal(ctx:get(demon, component.ACTOR).kind_id,
        monsters.MONS_HELL_HOG, "demonic monster becomes a hell hog")
    harness.equal(ctx:get(holy, component.ACTOR).kind_id,
        monsters.MONS_HOLY_SWINE, "holy monster becomes holy swine")

    local death_game = fixture.context(ctx, summoner)

    death_hooks.run(death_game, caster,
        catalog.get("monsters", monsters.MONS_KIRKE),
        ctx:get(caster, component.POSITION), true)
    harness.equal(ctx:get(target, component.ACTOR).kind_id,
        monsters.MONS_ORC, "Kirke's death restores the original kind")
    harness.equal(ctx:get(demon, component.ACTOR).kind_id,
        monsters.MONS_APOCALYPSE_CRAB,
        "Kirke's death restores demonic original")
    harness.equal(ctx:get(holy, component.ACTOR).kind_id,
        monsters.MONS_ANGEL, "Kirke's death restores holy original")
    harness.equal(targets.real_attitude(death_game, target),
        attitudes.GOOD_NEUTRAL,
        "a summoned former hog becomes good-neutral despite its old side")

    -- Reverting a spell victim must not break a different band's follower
    -- relationship. Only Kirke's original hogs lose their leader links.
    local jackal_leader = fixture.actor(ctx, monsters.MONS_JACKAL, 13, 8)
    local jackal = fixture.actor(ctx, monsters.MONS_JACKAL, 14, 8)

    ctx:add(jackal, component.FOLLOWER, {
        leader = jackal_leader,
    })
    ctx:add(jackal, component.AI, {
        behavior = "wander",
    })
    pork.apply(game, caster, jackal, { cap = 100 })
    death_hooks.run(game, caster,
        catalog.get("monsters", monsters.MONS_KIRKE),
        ctx:get(caster, component.POSITION), true)
    harness.equal(ctx:get(jackal, component.ACTOR).kind_id,
        monsters.MONS_JACKAL, "jackal spell victim returns to jackal form")
    harness.equal(ctx:get(jackal, component.FOLLOWER).leader,
        jackal_leader, "jackal band link survives spell restoration")
    links.validate(game)
end

-- The original band is not a collection of porkalated monsters. It has its
-- own origin, so unrelated hogs remain hogs when Kirke dies.
local function original_band(ctx)
    local second_kirke = fixture.actor(ctx, monsters.MONS_KIRKE, 20, 20)
    local other_hog = fixture.actor(ctx, monsters.MONS_HOG, 22, 20)
    local band_game = fixture.context(ctx, other_hog)
    local followers = bands.spawn(band_game, second_kirke, {
        id = 1,
        entry_x = 1,
        entry_y = 1,
    }, {})

    harness.truthy(followers >= 3 and followers <= 8,
        "Kirke starts with three to eight band hogs")

    local band_hogs = ctx:query({ tactical.KIRKE_BAND, component.ACTOR })

    harness.equal(#band_hogs, followers,
        "each band hog owns a saved origin marker")

    links.validate(band_game)

    -- Save-link validation follows Kirke's original identity even when she
    -- currently wears a different monster body.
    ctx:set(second_kirke, component.ACTOR, {
        kind_id = monsters.MONS_ORC,
        speed = 10,
    })
    ctx:add(second_kirke, component.MONSTER_POLYMORPH, {
        original_kind_id = monsters.MONS_KIRKE,
    })
    links.validate(band_game)

    local away_hog = band_hogs[1]
    local away_position = ctx:get(away_hog, component.POSITION)

    away_position.level_id = 2
    ctx:set(away_hog, component.POSITION, away_position)
    ctx:remove(away_hog, component.FOLLOWER)
    death_hooks.run(band_game, second_kirke,
        catalog.get("monsters", monsters.MONS_ORC),
        ctx:get(second_kirke, component.POSITION), true)

    for _, hog in ipairs(band_hogs) do
        harness.equal(ctx:get(hog, component.ACTOR).kind_id,
            monsters.MONS_HUMAN,
            "Kirke's band hog returns to human form across levels")
        harness.falsy(ctx:has(hog, tactical.KIRKE_BAND),
            "restoration consumes band origin")
        harness.falsy(ctx:has(hog, component.FOLLOWER),
            "human no longer follows its dead band leader")
        harness.equal(targets.real_attitude(band_game, hog),
            attitudes.GOOD_NEUTRAL,
            "released band human does not attack the player")
    end

    harness.equal(ctx:get(other_hog, component.ACTOR).kind_id,
        monsters.MONS_HOG, "unrelated hog is unchanged")
end

-- The source fineff releases the player last. An uncancellable Pig Form must
-- end immediately when Kirke dies, without waiting for its timer.
local function player_pig(ctx)
    local player = ctx:create()
    local player_game = fixture.context(ctx, player)
    local kirke = fixture.actor(ctx, monsters.MONS_KIRKE, 24, 24)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 1,
    })
    ctx:add(player, component.SKILLS, {
        entries = {},
    })

    local base_max = forms.max_hp(player_game, player)

    ctx:add(player, component.HEALTH, {
        current = base_max,
        max = base_max,
    })
    ctx:add(player, component.REGENERATION, {
        hp_progress = 0,
        mp_progress = 0,
    })
    ctx:add(player, component.PLAYER_FORM, {
        form_id = form_ids.PIG,
        remaining_aut = 100,
        uncancellable = true,
    })
    ctx:set(kirke, component.ACTOR, {
        kind_id = monsters.MONS_ORC,
        speed = 10,
    })
    ctx:add(kirke, component.MONSTER_POLYMORPH, {
        original_kind_id = monsters.MONS_KIRKE,
    })
    death_hooks.run(player_game, kirke,
        catalog.get("monsters", monsters.MONS_ORC),
        ctx:get(kirke, component.POSITION), true)
    harness.falsy(ctx:has(player, component.PLAYER_FORM),
        "polymorphed Kirke's death ends the player's forced Pig Form")
end

-- Keep the three source paths independent, but run them against the same
-- production schemas and policy modules used by the Go game.
function test.run(ctx)
    spell_hogs(ctx)
    original_band(ctx)
    player_pig(ctx)
end

return test
