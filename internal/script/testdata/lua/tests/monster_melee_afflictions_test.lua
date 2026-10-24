-- Source melee afflictions must reach the same saved statuses as spells,
-- scrolls, and missiles after either kind of defender survives contact.
local attacks = require("policy.combat.monster_attack_flavours")
local actions = require("policy.combat.melee_actions")
local attack_types = require("constants.monster_attack_types")
local artefact_kinds = require("constants.artefact_kinds")
local artefact_properties = require("ids.artefact_properties")
local catalog = require("policy.catalog")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local flavours = require("constants.attack_flavours")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local items = require("ids.items")
local jewellery_slots = require("constants.jewellery_slots")
local jobs = require("ids.jobs")
local species = require("ids.species")
local monster_stats = require("policy.combat.monster_stats")

local test = {}

-- A direct hit uses the same envelope constructed by the live monster
-- melee owner, including the selected attack type for spore contacts.
local function hit(attacker, defender, definition, attack_type)
    return {
        kind = "hit",
        attacker = attacker,
        attacker_name = "afflicting monster",
        defender = defender,
        defender_definition = definition,
        attack_type = attack_type or attack_types.HIT,
        hit_dice = 8,
        damage_done = 4,
    }
end

-- Chance gates use the melee stream; monster will contests use the spell
-- stream. High spell draws force an otherwise eligible victim to fail.
local function chance_succeeds(game)
    function game:random(stream, bound)
        if stream == "spell" or bound == 100 or bound == 101 then
            return bound - 1
        end

        return 0
    end
end

-- The wound owner handles movement damage and timed removal. These
-- contacts only need to lodge its already defined player/monster state.
local function barbs(ctx, game, attacker, player, orc)
    attacks.apply(game, flavours.BARBS, hit(attacker, player))

    harness.truthy(ctx:has(player, component.BARBS),
        "barbed melee hit lodges a saved player wound")

    attacks.apply(game, flavours.BARBS, hit(attacker, orc,
        catalog.get("monsters", monsters.MONS_ORC)))

    harness.truthy(ctx:has(orc, component.BARBS),
        "barbed melee hit lodges a saved monster wound")

    local amount = ctx:get(orc, component.BARBS).remaining_aut
    local dry = hit(attacker, orc,
        catalog.get("monsters", monsters.MONS_ORC))

    dry.damage_done = 0
    attacks.apply(game, flavours.BARBS, dry)

    harness.equal(ctx:get(orc, component.BARBS).remaining_aut, amount,
        "zero-damage hit cannot extend a barb wound")
end

-- A spore contact consumes one source HD before its confusion chance.
-- Unbreathing victims prevent both spore consumption and confusion.
local function confusion(ctx, game, player, orc)
    local spore = fixture.actor(ctx, monsters.MONS_DEATHCAP,
        15, 10, 100)
    local definition = catalog.get("monsters", monsters.MONS_DEATHCAP)
    local before = monster_stats.hit_dice(game, spore, definition)

    attacks.apply(game, flavours.CONFUSE,
        hit(spore, player, nil, attack_types.SPORE))

    harness.truthy(ctx:has(player, "zap.player_confusion"),
        "spore melee confuses a breathing player")
    harness.equal(monster_stats.hit_dice(game, spore, definition),
        before - 1, "spore melee consumes one attacker HD")

    attacks.apply(game, flavours.CONFUSE, hit(spore, orc,
        catalog.get("monsters", monsters.MONS_ORC),
        attack_types.TOUCH))

    harness.truthy(ctx:has(orc, component.MONSTER_CONFUSION),
        "ordinary Confuse contact affects a monster defender")

    local undead = fixture.actor(ctx, monsters.MONS_WRAITH,
        16, 10, 100)

    attacks.apply(game, flavours.CONFUSE, hit(spore, undead,
        catalog.get("monsters", monsters.MONS_WRAITH),
        attack_types.SPORE))

    harness.equal(monster_stats.hit_dice(game, spore, definition),
        before - 1, "unbreathing victim saves the spore's HD")
    harness.falsy(ctx:has(undead, component.MONSTER_CONFUSION),
        "unbreathing victim ignores the spore cloud")

    local djinni = fixture.actor(ctx, monsters.MONS_HUMAN,
        20, 10, 100)

    ctx:add(djinni, component.PLAYER, {
        species_id = species.SP_DJINNI,
    })

    attacks.apply(game, flavours.CONFUSE,
        hit(spore, djinni, nil, attack_types.SPORE))

    harness.equal(monster_stats.hit_dice(game, spore, definition),
        before - 1, "nonliving Djinni does not consume spore HD")
    harness.falsy(ctx:has(djinni, "zap.player_confusion"),
        "nonliving Djinni ignores confusing spores")

    local spent = fixture.actor(ctx, monsters.MONS_DEATHCAP,
        21, 10, 100)

    ctx:add(spent, component.MONSTER_SPORE_EXHAUSTION, {
        lost_hd = before - 1,
    })

    attacks.apply(game, flavours.CONFUSE,
        hit(spent, player, nil, attack_types.SPORE))

    harness.equal(ctx:get(spent, component.HEALTH).current, 0,
        "a mushroom that spends its last HD dies after contact")
end

-- Source Vulnerability adds player time up to 40 turns and places the
-- monster's will reduction on the common enchantment component.
local function vulnerability(ctx, game, attacker, player, orc)
    local attack = hit(attacker, player)

    attacks.apply(game, flavours.VULNERABILITY, attack)

    harness.equal(ctx:get(player,
        component.PLAYER_STATUS).lowered_will_aut, 200,
        "first vulnerable contact grants 20 turns")

    attacks.apply(game, flavours.VULNERABILITY, attack)
    attacks.apply(game, flavours.VULNERABILITY, attack)

    harness.equal(ctx:get(player,
        component.PLAYER_STATUS).lowered_will_aut, 400,
        "repeated contacts cap lowered will at 40 turns")

    attacks.apply(game, flavours.VULNERABILITY, hit(attacker, orc,
        catalog.get("monsters", monsters.MONS_ORC)))

    harness.truthy(ctx:has(orc, component.MONSTER_LOWERED_WILL),
        "monster victim owns a saved lowered-will enchantment")

    local briar = fixture.actor(ctx, monsters.MONS_BRIAR_PATCH,
        22, 10, 100)

    attacks.apply(game, flavours.VULNERABILITY,
        hit(attacker, briar,
            catalog.get("monsters", monsters.MONS_BRIAR_PATCH)))

    harness.falsy(ctx:has(briar, component.MONSTER_LOWERED_WILL),
        "invulnerable willpower blocks contact vulnerability")
end

-- Rage on a monster reuses its frenzy and fatigue owner. A player uses
-- the ordinary Rage owner so its HP rescaling and command limits agree.
local function rage(ctx, game, attacker, orc)
    attacks.apply(game, flavours.RAGE, hit(attacker, orc,
        catalog.get("monsters", monsters.MONS_ORC)))

    harness.truthy(ctx:has(orc, component.MONSTER_ALLEGIANCE),
        "Rage contact starts the monster's saved frenzy")

    local state = ctx:get(orc, component.MONSTER_ALLEGIANCE)

    harness.truthy(state.frenzy_aut > 0,
        "Rage contact grants positive frenzy time")

    local wraith = fixture.actor(ctx, monsters.MONS_WRAITH,
        23, 10, 100)

    attacks.apply(game, flavours.RAGE, hit(attacker, wraith,
        catalog.get("monsters", monsters.MONS_WRAITH)))

    harness.falsy(ctx:has(wraith, component.MONSTER_ALLEGIANCE),
        "undead monster cannot be made berserk by melee")

    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        18, 10, 100)

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
    ctx:add(player, component.REGENERATION, {
        hp_progress = 0,
        mp_progress = 0,
    })

    local player_game = fixture.context(ctx, player)

    chance_succeeds(player_game)
    attacks.apply(player_game, flavours.RAGE,
        hit(attacker, player))

    harness.truthy(ctx:has(player, component.RAGE),
        "player Rage contact uses the saved health and fatigue owner")

    ctx:remove(player, component.RAGE)

    local ring = ctx:create()

    ctx:add(ring, component.ITEM, {
        kind_id = items.RING_PROTECTION,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(ring, component.CARRIED_BY, {
        holder = player,
    })
    ctx:add(ring, component.EQUIPPED, {
        slot = jewellery_slots.LEFT,
    })
    ctx:add(ring, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.RANDOM,
        properties = {
            [artefact_properties.CLARITY] = 1,
        },
    })

    attacks.apply(player_game, flavours.RAGE,
        hit(attacker, player))

    harness.falsy(ctx:has(player, component.RAGE),
        "worn Clarity prevents involuntary Rage contact")
end

-- Poison Paralysis runs poisoning and control independently. A fully
-- poison-immune body must reject both before either chance consumes RNG.
local function poison_paralysis(ctx, game, attacker, player, orc)
    attacks.apply(game, flavours.POISON_PARALYSE,
        hit(attacker, player))

    harness.truthy(ctx:has(player, component.POISON),
        "venomous control contact poisons a susceptible player")
    harness.truthy(ctx:has(player, component.PLAYER_PARALYSIS),
        "one-in-six branch paralyses the player")

    attacks.apply(game, flavours.POISON_PARALYSE,
        hit(attacker, orc,
            catalog.get("monsters", monsters.MONS_ORC)))

    harness.truthy(ctx:has(orc, component.PROJECTILE_POISON),
        "venomous control contact poisons a monster")
    harness.truthy(ctx:has(orc, component.PARALYSIS),
        "one-in-six branch paralyses a monster")

    local wraith = fixture.actor(ctx, monsters.MONS_WRAITH,
        17, 10, 100)
    local draws = 0

    function game:random(_, bound)
        draws = draws + 1

        return 0
    end

    attacks.apply(game, flavours.POISON_PARALYSE,
        hit(attacker, wraith,
            catalog.get("monsters", monsters.MONS_WRAITH)))

    harness.equal(draws, 0,
        "poison immunity rejects the contact before chance rolls")
    harness.falsy(ctx:has(wraith, component.PARALYSIS),
        "poison-immune monster cannot be paralysed by venom")

    local slowed = fixture.actor(ctx, monsters.MONS_ORC,
        19, 10, 100)

    function game:random(_, bound)
        if bound == 6 then
            return 1
        end

        if bound == 100 or bound == 101 then
            return bound - 1
        end

        return 0
    end

    attacks.apply(game, flavours.POISON_PARALYSE,
        hit(attacker, slowed,
            catalog.get("monsters", monsters.MONS_ORC)))

    harness.truthy(ctx:has(slowed, component.PROJECTILE_SLOW),
        "five-in-six branch slows a monster instead of paralysis")
    harness.equal(ctx:get(slowed,
        component.PROJECTILE_SLOW).remaining_aut, 10,
        "monster venom Slow lasts the rolled one turn")

    local formicid = fixture.actor(ctx, monsters.MONS_FORMICID,
        24, 10, 100)
    local will_draws = 0

    function game:random(stream, bound)
        if bound == 6 then
            return 0
        end

        if stream == "melee" and bound == 3 then
            return 0
        end

        if bound == 100 or bound == 101 then
            will_draws = will_draws + 1

            return bound - 1
        end

        return 0
    end

    attacks.apply(game, flavours.POISON_PARALYSE,
        hit(attacker, formicid,
            catalog.get("monsters", monsters.MONS_FORMICID)))

    harness.falsy(ctx:has(formicid, component.PARALYSIS),
        "Formicid stasis prevents venom paralysis")
    harness.falsy(ctx:has(formicid, component.PROJECTILE_SLOW),
        "Formicid stasis prevents venom slowing")
    harness.equal(will_draws, 0,
        "intrinsic stasis prevents a monster will contest")
end

-- The source steelbarb worm's catalog slot reaches the same saved wound
-- through live melee, after the defender's real armour and evasion roll.
local function live_barbs(ctx)
    local worm = fixture.actor(ctx, monsters.MONS_STEELBARB_WORM,
        30, 30, 1000)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        31, 30, 1000)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 27,
    })
    ctx:add(player, component.ATTRIBUTES, {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(player, component.SKILLS, {
        entries = {},
    })
    ctx:add(player, component.COMBAT, {
        shield_blocks = 0,
    })

    local game = fixture.context(ctx, player)

    function game:random(_, bound)
        return bound - 1
    end

    actions.monster(game, worm)

    harness.truthy(ctx:has(player, component.BARBS),
        "live steelbarb worm melee lodges source barbs")
end

-- Each case reads production IDs and ECS schemas, so definition changes
-- are visible to the test rather than duplicated in a synthetic harness.
function test.run(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_MOTH_OF_WRATH,
        10, 10, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        11, 10, 100)
    local orc = fixture.actor(ctx, monsters.MONS_ORC,
        12, 10, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local game = fixture.context(ctx, player)

    chance_succeeds(game)
    barbs(ctx, game, attacker, player, orc)
    confusion(ctx, game, player, orc)
    vulnerability(ctx, game, attacker, player, orc)
    rage(ctx, game, attacker, orc)
    poison_paralysis(ctx, game, attacker, player, orc)
    live_barbs(ctx)
end

return test
