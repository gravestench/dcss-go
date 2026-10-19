-- These rule tests use real ECS components with a sparse map. They verify
-- that combat reads the saved ghost body rather than its static catalog row.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local defense = require("policy.combat.monster_defense")
local effect = require("policy.combat.monster_spells.summon_illusion")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local items = require("ids.items")
local skills = require("ids.skills")
local jewellery_fixture = require("tests.fixtures.jewellery")
local magic_damage = require("policy.magic.damage")
local miasma = require("policy.clouds.effects.miasma")
local monsters = require("ids.monsters")
local illusion = require("policy.combat.monster_summons.player_illusion")
local profile = require("policy.combat.monster_profile")
local resistance_ids = require("constants.resistance_ids")
local save_summons = require("policy.save.summons")
local spellbook = require("policy.combat.monster_spellbook")
local summon_melee = require("policy.combat.summon_melee")
local spells = require("ids.spells")
local species = require("ids.species")
local weapon_brands = require("constants.weapon_brands")
local holiness = require("constants.monster_holiness")
local attitudes = require("constants.attitude")

local test = {}

-- The exact saved component shape is shared with production registration;
-- tests specify values, not a second schema or alternate profile resolver.
local function saved_profile()
    return {
        name = "A reader",
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        ac = 7,
        ev = 15,
        damage = 12,
        brand_id = weapon_brands.NORMAL,
        holiness_id = holiness.NATURAL,
        see_invisible = true,
        resistances = {
            [resistance_ids.FIRE] = 1,
            [resistance_ids.MIASMA] = 3,
        },
        spell_ids = {
            spells.SPELL_MAGIC_DART,
        },
        frequencies = { 55 },
    }
end

-- Save validation receives the same actor, plan, and summon components as
-- restore, without rebuilding ghost values from the current player.
local function validate(ctx, game, ghost)
    local actor = ctx:get(ghost, component.ACTOR)
    local position = ctx:get(ghost, component.POSITION)
    local ai = ctx:get(ghost, component.AI)
    local summon = ctx:get(ghost, component.SUMMON)

    return pcall(save_summons.validate, game, ghost,
        actor, position, ai, summon, 0)
end

-- An existing named illusion blocks Mara's next cast, and a forged profile
-- must be rejected before it can affect restored combat.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 10, 10)
    local caster = fixture.actor(ctx, monsters.MONS_MARA, 12, 10)
    local game = fixture.context(ctx, player)

    ctx:add(player, component.PLAYER, {
        name = "A reader",
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })

    harness.truthy(effect.plan(game, caster, player),
        "visible player permits Mara's illusion")

    local ghost = fixture.actor(ctx,
        monsters.MONS_PLAYER_ILLUSION, 13, 10)
    local original = saved_profile()

    ctx:add(ghost, component.PLAYER_ILLUSION, original)
    ctx:add(ghost, component.SUMMON_STATS, { hd = 5 })
    ctx:add(ghost, component.SUMMON, {
        owner = caster,
        source_category = categories.SPELLS,
        source_id = spells.SPELL_SUMMON_ILLUSION,
        expires_aut = 100,
        heads = 0,
        attitude = attitudes.HOSTILE,
    })
    ctx:add(ghost, component.AI, {
        behavior = "wander",
        target_x = 0,
        target_y = 0,
        memory_until_aut = 0,
    })

    harness.falsy(effect.plan(game, caster, player),
        "one living copy of this player blocks another cast")

    local definition = catalog.get(categories.MONSTERS,
        monsters.MONS_PLAYER_ILLUSION)
    local body = profile.definition(game, ghost, definition)

    harness.equal(body.attacks[1].damage, 12,
        "melee uses captured damage instead of catalog damage")
    harness.equal(defense.armour(game, ghost, definition), 7,
        "armour reads the captured player AC")
    harness.equal(defense.evasion(game, ghost, definition), 15,
        "evasion reads the captured player EV")
    harness.equal(magic_damage.monster_elemental(game, ghost,
        30, resistance_ids.FIRE), 15,
        "fire damage reads captured resistance")
    harness.truthy(miasma.immune(game, ghost),
        "miasma reads the saved illusion resistance")

    local book = spellbook.for_actor(game, ghost)

    harness.equal(book.slots[1].spell_id,
        spells.SPELL_MAGIC_DART,
        "AI reads the captured player spell")
    harness.equal(book.slots[1].frequency, 55,
        "AI retains the saved ghost frequency")

    local victim = fixture.actor(ctx, monsters.MONS_RAT, 16, 10, 30)

    -- Make contact and damage rolls maximal to expose the saved attack.
    function game:random(_, bound)
        return bound - 1
    end

    harness.truthy(summon_melee.attack(game, ghost, victim),
        "saved illusion takes the summon monster-melee path")
    harness.truthy(ctx:get(victim, component.HEALTH).current < 25,
        "monster-target strike uses saved damage, not catalog damage")

    local ok, err = validate(ctx, game, ghost)

    harness.truthy(ok, "valid ghost saves: " .. tostring(err))

    local forged = ctx:get(ghost, component.PLAYER_ILLUSION)

    forged.damage = 60
    ctx:set(ghost, component.PLAYER_ILLUSION, forged)

    ok = validate(ctx, game, ghost)

    harness.falsy(ok, "restore rejects impossible ghost melee damage")

    forged.damage = 12
    forged.frequencies = { 200 }
    ctx:set(ghost, component.PLAYER_ILLUSION, forged)

    ok = validate(ctx, game, ghost)

    harness.falsy(ok, "restore rejects forged ghost spell weights")

    forged.frequencies = { 55 }
    ctx:set(ghost, component.PLAYER_ILLUSION, forged)

    local duplicate = fixture.actor(ctx,
        monsters.MONS_PLAYER_ILLUSION, 14, 10)

    ctx:add(duplicate, component.PLAYER_ILLUSION, saved_profile())

    ok = validate(ctx, game, ghost)

    harness.falsy(ok, "restore rejects two illusions of one named player")

    ctx:remove(ghost, component.PLAYER_ILLUSION)
    ok = validate(ctx, game, ghost)
    harness.falsy(ok, "restore rejects illusion actor without a profile")

    -- A monster foe uses the other source branch. Its body stays beside
    -- the original, with no Phantom Mirror swap or constraint release.
    local foe = fixture.actor(ctx, monsters.MONS_ORC, 18, 10, 35)

    ctx:add(foe, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })
    ctx:add(foe, component.MONSTER_ALLEGIANCE, {
        charm_aut = 30,
    })

    local monster_plan = effect.plan(game, caster, foe)

    harness.truthy(monster_plan,
        "visible enemy monster permits a source illusion")
    effect.resolve(game, caster, foe, nil, monster_plan)

    local monster_copy

    for _, entity in ipairs(ctx:query({ component.SUMMON_MIRROR })) do
        local state = ctx:get(entity, component.SUMMON)

        if state.source_id == spells.SPELL_SUMMON_ILLUSION then
            monster_copy = entity
        end
    end

    harness.truthy(monster_copy,
        "monster foe creates a mirror body")
    harness.equal(ctx:get(foe, component.POSITION).x, 18,
        "monster illusion never swaps the source")
    harness.equal(ctx:get(monster_copy, component.HEALTH).current, 35,
        "monster illusion keeps the source's current life")
    harness.equal(ctx:get(monster_copy,
        component.MONSTER_ALLEGIANCE).charm_aut, 0,
        "monster illusion discards the source's charm")
    harness.falsy(effect.plan(game, caster, foe),
        "one source monster cannot have two live illusions")
    harness.falsy(effect.plan(game, caster, monster_copy),
        "a mirror body cannot seed recursive illusions")

    local copy_actor = ctx:get(monster_copy, component.ACTOR)
    local copy_position = ctx:get(monster_copy, component.POSITION)
    local copy_ai = ctx:get(monster_copy, component.AI)
    local copy_state = ctx:get(monster_copy, component.SUMMON)

    copy_ai.target_x = copy_ai.target_x or 0
    copy_ai.target_y = copy_ai.target_y or 0
    copy_ai.memory_until_aut = copy_ai.memory_until_aut or 0

    local saved, reason = pcall(save_summons.validate, game,
        monster_copy, copy_actor, copy_position, copy_ai, copy_state, 0)

    harness.truthy(saved,
        "monster illusion saves: " .. tostring(reason))

    -- A second fixture player has production player components, allowing
    -- capture to exercise the real player formulas and read-only form view.
    local _, source = jewellery_fixture.player(ctx)
    local source_game = fixture.context(ctx, source)

    ctx:add(source, component.PROGRESSION, {
        level = 1,
        total_xp = 0,
    })
    ctx:add(source, component.HEALTH, {
        current = 20,
        max = 20,
    })
    ctx:add(source, component.DURATIONS, {
        haste_aut = 0,
        might_aut = 0,
    })

    -- Stable ghost spell selection leaves the profile capture reproducible.
    function source_game:random()
        return 0
    end

    local snapshot = illusion.capture(source_game, source)

    harness.equal(snapshot.name, "Jewellery test",
        "capture uses the player's current saved identity")
    harness.truthy(snapshot.hp > 0 and snapshot.hp <= 400,
        "capture uses source bounded real maximum HP")
    harness.truthy(snapshot.damage > 5,
        "capture builds ghost melee from player Strength")
    harness.equal(snapshot.brand_id, weapon_brands.NORMAL,
        "unarmed capture uses the normal ghost brand")

    local weapon = jewellery_fixture.carry(ctx, source,
        items.WPN_SPIKED_FLAIL)

    ctx:add(weapon, component.EQUIPPED, { slot = "weapon" })
    ctx:set(source, component.SKILLS, {
        entries = {
            {
                id = skills.SK_MACES_FLAILS,
                level = 20,
                points = 0,
            },
        },
    })

    local armed = illusion.capture(source_game, source)

    harness.equal(armed.damage, 11,
        "melee ghost damage uses weapon skill for MI_NONE weapon")

    ctx:set(source, component.PLAYER, {
        name = "Stone reader",
        species_id = species.SP_GARGOYLE,
        job_id = jobs.JOB_FIGHTER,
        starting_weapon_id = items.WPN_SPIKED_FLAIL,
    })

    local stone = illusion.capture(source_game, source)

    harness.equal(stone.holiness_id, holiness.NONLIVING,
        "Gargoyle illusion retains nonliving holiness")
    harness.equal(stone.resistances[resistance_ids.MIASMA], 3,
        "Gargoyle illusion retains miasma immunity")
end

return test
