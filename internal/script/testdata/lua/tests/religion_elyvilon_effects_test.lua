-- Elyvilon's four effects use real catalog, component, resource, and
-- allegiance owners. The fixture supplies only a sparse grid and player.
local abilities = require("ids.abilities")
local behaviors = require("constants.ai_behaviors")
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local cleansing = require("policy.religion.elyvilon.cleansing")
local component = require("constants.component")
local death = require("policy.death")
local fixture = require("tests.monster_ally_support_fixture")
local formulas = require("policy.character.formulas")
local gods = require("constants.gods")
local harness = require("tests.harness")
local items = require("ids.items")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local pacification = require("policy.religion.elyvilon.pacification")
local piety = require("policy.religion.piety")
local patron = require("policy.religion.gods.elyvilon")
local registry = require("policy.abilities.registry")
local species = require("ids.species")
local stats = require("constants.stats")
local tactical = require("constants.monster_tactical")
local targets = require("policy.ai.targets")
local temporary_terrain = require("policy.world.temporary_terrain")
local terrain = require("constants.terrain")
local vigour = require("policy.religion.elyvilon.vigour")
local zap = require("policy.magic.effects.zaps.ids").component

local test = {}

-- Build one ordinary Human who can gain XP, heal, and recalculate derived
-- HP/MP through exactly the same schemas as a live player.
local function worshipper(ctx)
    local player = ctx:create()
    local game = fixture.context(ctx, player)
    local human = catalog.get("species", species.SP_HUMAN)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 10,
        total_xp = 0,
    })
    ctx:add(player, component.SKILLS, { entries = {} })
    ctx:add(player, component.SKILL_TRAINING, {
        available_xp = 0,
        cost_level = 1,
        settings = {},
        recent_practice = {},
        recent_all = {},
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 10,
        y = 10,
    })
    ctx:add(player, component.REGENERATION, {
        hp_progress = 0,
        mp_progress = 0,
    })
    ctx:add(player, component.HEALTH, {
        current = 40,
        max = formulas.max_hp(game, player, 10, human, {}),
    })
    ctx:add(player, component.MAGIC, {
        current = 2,
        max = formulas.max_mp(game, player, 10, human, {}),
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.ELYVILON,
        piety = piety.breakpoint(5),
        penance = {},
    })

    -- Highest draws make source failure checks pass while retaining
    -- deterministic dice and a reproducible pacification chance.
    function game:random(_, bound)
        return bound - 1
    end

    return game, player
end

-- Purification clears every currently represented source ailment, and
-- the drained HP cap returns through the ordinary resource formula.
local function purification(game, player)
    local health = game:get(player, component.HEALTH)
    local normal_max = health.max

    health.max = health.max - 2
    health.current = 25
    game:set(player, component.HEALTH, health)
    game:add(player, component.PLAYER_DRAIN, { amount = 2 })
    game:add(player, component.POISON, {
        amount_scaled = 1000,
        source_monster_id = "",
    })
    game:add(player, zap.PLAYER_CONFUSION, {
        remaining_aut = 10,
    })
    game:add(player, component.PLAYER_SLOW, {
        remaining_aut = 20,
    })
    game:add(player, component.PLAYER_WEAKNESS, {
        remaining_aut = 20,
    })
    game:add(player, component.PLAYER_PETRIFICATION, {
        petrifying_aut = 20,
        petrified_aut = 0,
    })
    game:add(player, component.STAT_LOSS, {
        [stats.STRENGTH] = 1,
        remaining_xp = 30,
    })

    harness.truthy(cleansing.needed(game, player))
    cleansing.apply(game, player)
    harness.falsy(cleansing.needed(game, player))
    harness.equal(game:get(player, component.HEALTH).max, normal_max)
    harness.equal(registry.get(
        abilities.ELYVILON_PURIFICATION).prepare(game, player),
        "Nothing ails you!")
end

-- A god change and first penance must remove the same saved status as
-- natural expiry, so no orphan percentage survives a religion transition.
local function vigour_patron_loss(ctx)
    local game, player = worshipper(ctx)
    local baseline = game:get(player, component.HEALTH).max

    vigour.invoke(game, player)
    patron.leave(game, player)
    harness.equal(vigour.amount(game, player), 0)
    harness.equal(game:get(player, component.HEALTH).max, baseline)

    vigour.invoke(game, player)
    patron.on_penance(game, player)
    harness.equal(vigour.amount(game, player), 0)
    harness.equal(game:get(player, component.HEALTH).max, baseline)
end

-- Geryon's Horn remains on the floor when its owner accepts peace. This
-- exception happens at conversion; ordinary carried gear departs later.
local function geryon_horn(ctx)
    local game, player = worshipper(ctx)
    local target = fixture.actor(ctx, monsters.MONS_GERYON,
        13, 10, 30)
    local horn = ctx:create()

    game:add(target, component.AI, {
        behavior = behaviors.WANDER,
    })
    game:add(target, component.PLAYER_CONSTRICTION, {
        by = player,
        held_aut = 10,
        escape_attempts = 0,
    })
    game:add(horn, component.ITEM, {
        kind_id = items.MISC_HORN_OF_GERYON,
        quantity = 1,
    })
    game:add(horn, component.CARRIED_BY, {
        holder = target,
    })

    harness.equal(pacification.attempt(game, player, target,
        20, 10000), "pacified")
    harness.falsy(game:has(horn, component.CARRIED_BY))
    harness.equal(game:get(horn, component.POSITION).x, 13)
end

-- Source Pikel's marked lemures vanish when he accepts peace, just as
-- they do when he dies or is banished. An unrelated lemure stays alive.
local function pikel_band(ctx)
    local game, player = worshipper(ctx)
    local pikel = fixture.actor(ctx, monsters.MONS_PIKEL,
        14, 10, 30)
    local minion = fixture.actor(ctx, monsters.MONS_LEMURE,
        15, 10, 20)
    local unrelated = fixture.actor(ctx, monsters.MONS_LEMURE,
        16, 10, 20)

    game:add(pikel, component.AI, {
        behavior = behaviors.WANDER,
    })
    game:add(minion, component.PIKEL_BAND, {
        band_member = true,
    })

    harness.equal(pacification.attempt(game, player, pikel,
        20, 10000), "pacified")
    harness.falsy(game:has(minion, component.ACTOR))
    harness.truthy(game:has(unrelated, component.ACTOR))
end

-- Kirke's naturally spawned hogs regain human bodies and a neutral side
-- on pacification, using the same durable owner as their death release.
local function kirke_hogs(ctx)
    local game, player = worshipper(ctx)
    local kirke = fixture.actor(ctx, monsters.MONS_KIRKE,
        14, 11, 30)
    local hog = fixture.actor(ctx, monsters.MONS_HOG,
        15, 11, 20)

    game:add(kirke, component.AI, {
        behavior = behaviors.WANDER,
    })
    game:add(hog, tactical.KIRKE_BAND, {
        band_member = true,
    })

    harness.equal(pacification.attempt(game, player, kirke,
        20, 10000), "pacified")
    harness.equal(game:get(hog, component.ACTOR).kind_id,
        monsters.MONS_HUMAN)
    harness.equal(targets.real_attitude(game, hog),
        attitudes.GOOD_NEUTRAL)
end

-- A Warden's seal is tied to that actor, so accepting Elyvilon's peace
-- restores the door immediately without waiting for its normal timer.
local function warden_seal(ctx)
    local game, player = worshipper(ctx)
    local warden = fixture.actor(ctx, monsters.MONS_VAULT_WARDEN,
        14, 13, 30)

    game:add(warden, component.AI, {
        behavior = behaviors.WANDER,
    })
    game.cells["14:14"] = terrain.DNGN_CLOSED_DOOR

    local placed, marker = temporary_terrain.place(game, warden,
        monsters.MONS_VAULT_WARDEN, 1, 14, 14,
        terrain.DNGN_SEALED_DOOR, 100)

    harness.truthy(placed)
    harness.equal(pacification.attempt(game, player, warden,
        20, 10000), "pacified")
    harness.equal(game:cell(1, 14, 14), terrain.DNGN_CLOSED_DOOR)
    harness.falsy(game:has(marker, component.TEMPORARY_TERRAIN))
end

-- A polymorphed Duvessa still finds Dowan by original class. Both real
-- sides change once, and each living twin contributes its own source XP.
local function elven_twins(ctx)
    local game, player = worshipper(ctx)
    local duvessa = fixture.actor(ctx, monsters.MONS_DUVESSA,
        14, 12, 30)
    local dowan = fixture.actor(ctx, monsters.MONS_DOWAN,
        15, 12, 30)
    local changed = game:get(duvessa, component.ACTOR)

    changed.kind_id = monsters.MONS_ORC
    game:set(duvessa, component.ACTOR, changed)
    game:add(duvessa, component.MONSTER_POLYMORPH, {
        original_kind_id = monsters.MONS_DUVESSA,
    })
    game:add(duvessa, component.AI, {
        behavior = behaviors.WANDER,
    })
    game:add(dowan, component.AI, {
        behavior = behaviors.WANDER,
    })

    local first = catalog.get(categories.MONSTERS, monsters.MONS_ORC)
    local second = catalog.get(categories.MONSTERS, monsters.MONS_DOWAN)
    local expected = death.experience(first, 100) +
        death.experience(second, 100)

    harness.equal(pacification.attempt(game, player, duvessa,
        20, 10000), "pacified")
    harness.equal(targets.real_attitude(game, duvessa),
        attitudes.NEUTRAL)
    harness.equal(targets.real_attitude(game, dowan),
        attitudes.NEUTRAL)
    harness.equal(game:get(player, component.PROGRESSION).total_xp,
        expected)

    pacification.attempt(game, player, duvessa, 20, 10000)
    harness.equal(game:get(player, component.PROGRESSION).total_xp,
        expected)
end

-- Self-healing uses the source base and two dice; at zero Invocations
-- and maximum RNG rolls it restores 28 HP before the max-HP clamp.
local function heal_self(game, player)
    local healing = registry.get(abilities.ELYVILON_HEAL_SELF)
    local health = game:get(player, component.HEALTH)

    health.current = 10
    game:set(player, component.HEALTH, health)
    harness.equal(healing.prepare(game, player), nil)
    local before_mp = game:get(player, component.MAGIC).current

    healing.resolve(game, player)
    harness.truthy(game:get(player, component.HEALTH).current > 10)
    harness.equal(game:get(player, component.MAGIC).current,
        before_mp - 2)
end

-- The same pacification marker changes real allegiance, survives the
-- owner's validator, and prevents a second XP reward on repeated use.
local function heal_other(game, player)
    local magic = game:get(player, component.MAGIC)

    magic.current = magic.max
    game:set(player, component.MAGIC, magic)

    local target = fixture.actor(game.base, monsters.MONS_ORC,
        11, 10, 10)

    game:add(target, component.AI, {
        behavior = behaviors.WANDER,
    })
    local healing = registry.get(abilities.ELYVILON_HEAL_OTHER)
    local request = { dx = 1, dy = 0 }
    local before_xp = game:get(player, component.PROGRESSION).total_xp

    harness.equal(healing.prepare(game, player, request), nil)
    healing.resolve(game, player, request)
    harness.equal(targets.real_attitude(game, target),
        attitudes.NEUTRAL)
    harness.falsy(game:has(target, component.PLAYER_CONSTRICTION))
    harness.truthy(game:get(player, component.PROGRESSION).total_xp >
        before_xp)
    pacification.validate(game)

    local after_xp = game:get(player, component.PROGRESSION).total_xp

    healing.resolve(game, player, request)
    harness.equal(game:get(player, component.PROGRESSION).total_xp,
        after_xp)
end

-- Eligibility derives from imported monster profiles and the live sleep
-- state. Such offers abort before spending magic or risking a failure roll.
local function ineligible_healing(ctx)
    local game, player = worshipper(ctx)
    local healing = registry.get(abilities.ELYVILON_HEAL_OTHER)
    local magic = game:get(player, component.MAGIC)
    local skeleton = fixture.actor(ctx, monsters.MONS_SKELETON,
        9, 10, 10)

    game:add(skeleton, component.AI, {
        behavior = behaviors.WANDER,
    })
    harness.equal(pacification.reason(game, skeleton,
        catalog.get(categories.MONSTERS, monsters.MONS_SKELETON)),
        "You cannot pacify mindless monsters!")
    healing.resolve(game, player, { dx = -1, dy = 0 })
    harness.equal(game:get(player, component.MAGIC).current,
        magic.current)

    local orc = fixture.actor(ctx, monsters.MONS_ORC, 8, 10, 10)

    game:add(orc, component.AI, {
        behavior = behaviors.SLEEP,
    })
    harness.equal(pacification.reason(game, orc,
        catalog.get(categories.MONSTERS, monsters.MONS_ORC)),
        "You cannot pacify this monster while it is asleep!")

    local tentacle = fixture.actor(ctx, monsters.MONS_KRAKEN_TENTACLE,
        7, 10, 10)

    harness.equal(pacification.reason(game, tentacle,
        catalog.get(categories.MONSTERS, monsters.MONS_KRAKEN_TENTACLE)),
        "You cannot pacify mindless monsters!")
end

-- A visible empty square still charges a successful Heal Other. This
-- prevents free probing for a monster that the player cannot see.
local function empty_healing(ctx)
    local game, player = worshipper(ctx)
    local healing = registry.get(abilities.ELYVILON_HEAL_OTHER)
    local before = game:get(player, component.MAGIC).current

    healing.resolve(game, player, { dx = 0, dy = 1 })
    harness.equal(game:get(player, component.MAGIC).current,
        before - 2)
end

-- A saved amount changes both formulas, then expires through the same
-- owner that clears it on departure or penance.
local function divine_vigour(game, player)
    local health = game:get(player, component.HEALTH)
    local magic = game:get(player, component.MAGIC)
    local old_hp = health.max
    local old_mp = magic.max

    vigour.invoke(game, player)
    harness.truthy(vigour.amount(game, player) > 0)
    harness.truthy(game:get(player, component.HEALTH).max > old_hp)
    harness.truthy(game:get(player, component.MAGIC).max >= old_mp)
    vigour.validate(game, player)

    local state = game:get(player, component.ELYVILON_VIGOUR)

    vigour.tick(game, player, state.remaining_aut)
    harness.equal(vigour.amount(game, player), 0)
    harness.equal(game:get(player, component.HEALTH).max, old_hp)
    harness.equal(game:get(player, component.MAGIC).max, old_mp)
end

-- These checks share one player so cost payment and XP transitions are
-- exercised in the order a live game can encounter them.
function test.run(ctx)
    local game, player = worshipper(ctx)

    purification(game, player)
    heal_self(game, player)
    heal_other(game, player)
    divine_vigour(game, player)
    ineligible_healing(ctx)
    empty_healing(ctx)
    vigour_patron_loss(ctx)
    geryon_horn(ctx)
    pikel_band(ctx)
    kirke_hogs(ctx)
    warden_seal(ctx)
    elven_twins(ctx)
end

return test
