-- Source monster contacts resolve abstract stat drain on each attack,
-- then apply life and magic effects through saved actor components.
local attacks = require("policy.combat.monster_attack_sequence")
local actions = require("policy.combat.melee_actions")
local catalog = require("policy.catalog")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local flavours = require("constants.attack_flavours")
local form_ids = require("constants.form_ids")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local pan_lord = require("policy.population.pan_lord")
local effects = require("policy.combat.monster_attack_flavours")
local spells = require("ids.spells")
local species = require("ids.species")
local stat_loss = require("policy.character.stat_loss")
local stats = require("constants.stats")

local test = {}

-- The melee owner supplies the same resolved contact to player and monster
-- effects. The monster definition is present only for a monster defender.
local function contact(attacker, defender, definition)
    return {
        kind = "hit",
        attacker = attacker,
        attacker_name = "draining monster",
        defender = defender,
        defender_definition = definition,
        hit_dice = 8,
        damage_done = 4,
        player_credit = false,
    }
end

-- Give every source draw its first legal result. Individual tests replace
-- this when a second coin flip or immunity branch needs a different draw.
local function first_draw(game)
    function game:random(_, bound)
        harness.truthy(bound > 0, "life contact draw has positive bound")

        return 0
    end
end

-- The source catalog deliberately stores one abstract Drain Stat ID.
-- Resolve it anew for every contact so different claws in the same
-- round may drain different attributes.
local function stat_choice(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        10, 10, 100)
    local game = fixture.context(ctx, player)
    local choices = {
        flavours.DRAIN_STRENGTH,
        flavours.DRAIN_INTELLIGENCE,
        flavours.DRAIN_DEXTERITY,
    }
    local next_choice = 0

    function game:random(stream, bound)
        harness.equal(stream, "melee",
            "stat choice belongs to the melee RNG stream")
        harness.equal(bound, 3,
            "stat choice has three source alternatives")

        local chosen = next_choice

        next_choice = next_choice + 1

        return chosen
    end

    for _, wanted in ipairs(choices) do
        harness.equal(attacks.contact_flavour(game, flavours.DRAIN_STAT),
            wanted, "each abstract stat contact resolves independently")
    end

    harness.equal(attacks.contact_flavour(game, flavours.DRAIN),
        flavours.DRAIN, "ordinary Drain makes no selection draw")
end

-- Ghost moth claws keep their catalog's abstract ID until the actual
-- attack round. A confirmed hit then reaches the existing stat owner.
local function live_stat_contact(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_GHOST_MOTH,
        20, 20, 1000)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        21, 20, 1000)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Moth target",
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
        if bound == 20 or bound == 3 then
            return 0
        end

        return bound - 1
    end

    actions.monster(game, attacker)

    harness.truthy(stat_loss.amount(game, player,
        stats.STRENGTH) > 0,
        "live ghost moth claw resolves Drain Stat before its effect")
end

-- Drain first makes its flavour coin flip. A susceptible player then loses
-- temporary maximum HP through the saved drain owner; a zero-damage hit
-- never reaches that owner.
local function player_drain(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_WRAITH,
        30, 20, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        31, 20, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local game = fixture.context(ctx, player)
    local hit = contact(attacker, player)

    first_draw(game)
    effects.apply(game, flavours.DRAIN, hit)

    harness.truthy(ctx:has(player, component.PLAYER_DRAIN),
        "Drain adds recoverable maximum-HP loss to a living player")

    local amount = ctx:get(player, component.PLAYER_DRAIN).amount

    hit.damage_done = 0
    effects.apply(game, flavours.DRAIN, hit)

    harness.equal(ctx:get(player, component.PLAYER_DRAIN).amount, amount,
        "damageless Drain cannot increase the saved status")

    local lich = fixture.actor(ctx, monsters.MONS_HUMAN,
        32, 20, 100)

    ctx:add(lich, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    ctx:add(lich, component.PLAYER_FORM, {
        form_id = form_ids.LICH,
        remaining_aut = 100,
    })

    local lich_game = fixture.context(ctx, lich)

    first_draw(lich_game)
    effects.apply(lich_game, flavours.DRAIN,
        contact(attacker, lich))

    harness.equal(ctx:get(lich, component.HEALTH).max, 100,
        "Lich Form prevents temporary maximum-HP drain")
    harness.falsy(ctx:has(lich, component.PLAYER_DRAIN),
        "negative-energy immune player has no drain status")

    -- Source drain reduces maximum HP before the separate bonus damage.
    -- Reversing them would cap the earlier wound away as max HP falls.
    local ordered = fixture.actor(ctx, monsters.MONS_HUMAN,
        33, 20, 100)

    ctx:add(ordered, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local ordered_game = fixture.context(ctx, ordered)

    function ordered_game:random(_, bound)
        if bound == 4 then
            return 3
        end

        return 0
    end

    effects.apply(ordered_game, flavours.DRAIN,
        contact(attacker, ordered))

    harness.equal(ctx:get(ordered, component.HEALTH).max, 98,
        "source drain first lowers the player's maximum HP")
    harness.equal(ctx:get(ordered, component.HEALTH).current, 96,
        "negative-energy bonus lands after the drain cap")
end

-- A monster victim has a second coin-flip skip inside drain_defender.
-- Natural orcs can be drained, while undead wraiths are immune.
local function monster_drain(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_WRAITH,
        40, 20, 100)
    local orc = fixture.actor(ctx, monsters.MONS_ORC,
        41, 20, 100)
    local wraith = fixture.actor(ctx, monsters.MONS_WRAITH,
        42, 20, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        43, 20, 100)
    local game = fixture.context(ctx, player)
    local coins = 0

    function game:random(_, bound)
        if bound == 2 then
            coins = coins + 1

            return coins % 2 == 0 and 1 or 0
        end

        return 0
    end

    local hit = contact(attacker, orc,
        catalog.get("monsters", monsters.MONS_ORC))

    effects.apply(game, flavours.DRAIN, hit)

    harness.truthy(ctx:has(orc, component.MONSTER_DRAINED),
        "Drain adds the timed monster HD penalty")

    hit.defender = wraith
    hit.defender_definition = catalog.get("monsters",
        monsters.MONS_WRAITH)

    local before = ctx:get(wraith, component.HEALTH).current

    effects.apply(game, flavours.DRAIN, hit)

    harness.equal(ctx:get(wraith, component.HEALTH).current, before,
        "undead victim resists negative-energy contact")
    harness.falsy(ctx:has(wraith, component.MONSTER_DRAINED),
        "undead victim receives no saved drain")
    harness.equal(coins, 4,
        "monster-only skip coin precedes undead immunity")
end

-- Source natural Vampiric has no weapon-brand proc veto. A wounded
-- attacker heals even when the first melee draw would veto a brand.
local function vampiric(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_VAMPIRE,
        50, 20, 50)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        51, 20, 96)
    local game = fixture.context(ctx, player)
    local hit = contact(attacker, player)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    first_draw(game)
    effects.apply(game, flavours.VAMPIRIC, hit)

    harness.equal(ctx:get(attacker, component.HEALTH).current, 51,
        "natural Vampiric heals without a weapon-brand proc roll")

    hit.damage_done = 0
    effects.apply(game, flavours.VAMPIRIC, hit)

    harness.equal(ctx:get(attacker, component.HEALTH).current, 51,
        "damageless Vampiric cannot heal")

    local orc = fixture.actor(ctx, monsters.MONS_ORC,
        52, 20, 96)

    hit.damage_done = 4
    hit.defender = orc
    hit.defender_definition = catalog.get("monsters", monsters.MONS_ORC)

    effects.apply(game, flavours.VAMPIRIC, hit)

    harness.equal(ctx:get(attacker, component.HEALTH).current, 52,
        "natural monster defender can supply vampiric healing")

    local undead = fixture.actor(ctx, monsters.MONS_WRAITH,
        53, 20, 96)

    hit.defender = undead
    hit.defender_definition = catalog.get("monsters",
        monsters.MONS_WRAITH)

    effects.apply(game, flavours.VAMPIRIC, hit)

    harness.equal(ctx:get(attacker, component.HEALTH).current, 52,
        "undead defender cannot supply vampiric healing")

    -- Source spends the healing amount draw for an injured victim even
    -- when the attacker already has full health.
    local full = fixture.actor(ctx, monsters.MONS_VAMPIRE,
        54, 20, 100)
    local draws = 0

    hit.attacker = full
    hit.defender = orc
    hit.defender_definition = catalog.get("monsters", monsters.MONS_ORC)

    function game:random(stream, bound)
        if stream == "melee" and bound == hit.damage_done then
            draws = draws + 1
        end

        return 0
    end

    effects.apply(game, flavours.VAMPIRIC, hit)

    harness.equal(draws, 1,
        "full-health vampire still spends the source healing draw")
    harness.equal(ctx:get(full, component.HEALTH).current, 100,
        "full-health vampire cannot gain excess health")
end

-- Scarab combines the existing speed-drain roll with the same natural
-- Vampiric heal, in that order, rather than with a weapon brand chance.
local function scarab(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_DEATH_SCARAB,
        60, 20, 50)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        61, 20, 96)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local game = fixture.context(ctx, player)

    local melee_draws = {}

    function game:random(stream, bound)
        if stream == "melee" then
            melee_draws[#melee_draws + 1] = bound
        end

        return 0
    end

    effects.apply(game, flavours.SCARAB,
        contact(attacker, player))

    harness.equal(melee_draws[1], 5,
        "Scarab rolls speed-drain chance first")
    harness.equal(melee_draws[2], 7,
        "Scarab rolls speed strength before healing")
    harness.equal(melee_draws[3], 4,
        "Scarab reaches natural Vampiric heal draw last")
    harness.truthy(ctx:has(player, component.PLAYER_SLOW),
        "Scarab first applies saved speed drain")
    harness.equal(ctx:get(attacker, component.HEALTH).current, 51,
        "Scarab then applies natural Vampiric healing")
end

-- Pain's activation and bonus are independent Necromancy draws. Negative
-- energy immunity blocks the bonus even when both skill draws succeed.
local function pain(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_EIDOLON,
        70, 20, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        71, 20, 100)
    local orc = fixture.actor(ctx, monsters.MONS_ORC,
        72, 20, 100)
    local wraith = fixture.actor(ctx, monsters.MONS_WRAITH,
        73, 20, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local game = fixture.context(ctx, player)
    local hit = contact(attacker, player)

    function game:random(_, bound)
        return bound - 1
    end

    effects.apply(game, flavours.PAIN, hit)

    harness.truthy(ctx:get(player, component.HEALTH).current < 100,
        "Pain adds resisted damage to the player")

    hit.defender = orc
    hit.defender_definition = catalog.get("monsters", monsters.MONS_ORC)
    effects.apply(game, flavours.PAIN, hit)

    harness.truthy(ctx:get(orc, component.HEALTH).current < 100,
        "Pain adds resisted damage to a living monster")

    hit.defender = wraith
    hit.defender_definition = catalog.get("monsters",
        monsters.MONS_WRAITH)
    effects.apply(game, flavours.PAIN, hit)

    harness.equal(ctx:get(wraith, component.HEALTH).current, 100,
        "negative-energy immune monster takes no Pain bonus")
end

-- Natural Antimagic uses HD times twelve, unlike a weapon brand's
-- damage-times-eight power. Ghost moth recovers the MP it steals, and a
-- monster spellcaster receives the existing saved antimagic enchantment.
local function antimagic(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_GHOST_MOTH,
        80, 20, 50)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        81, 20, 100)
    local wizard = fixture.actor(ctx, monsters.MONS_ORC_WIZARD,
        82, 20, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    ctx:add(player, component.MAGIC, {
        current = 20,
        max = 20,
    })

    local game = fixture.context(ctx, player)
    local hit = contact(attacker, player)

    function game:random(_, bound)
        return bound - 1
    end

    effects.apply(game, flavours.ANTIMAGIC, hit)

    harness.equal(ctx:get(player, component.MAGIC).current, 9,
        "HD-eight Antimagic drains the player with power 96")
    harness.equal(ctx:get(attacker, component.HEALTH).current, 61,
        "ghost moth heals for the MP its contact drained")

    hit.defender = wizard
    hit.defender_definition = catalog.get("monsters",
        monsters.MONS_ORC_WIZARD)
    effects.apply(game, flavours.ANTIMAGIC, hit)

    harness.truthy(ctx:has(wizard, component.MONSTER_ENFEEBLE),
        "spellcasting monster receives saved antimagic")

    -- A generated Pan lord carries its active spell slots in a saved
    -- component; its catalog's MST_GHOST book contains no static slots.
    local lord = fixture.actor(ctx, monsters.MONS_PANDEMONIUM_LORD,
        84, 20, 100)
    local generated = pan_lord.roll(game, false)

    generated.spell_ids = {
        spells.SPELL_PAIN,
    }
    generated.frequencies = {
        20,
    }
    ctx:add(lord, component.PANDEMONIUM_LORD, generated)

    hit.defender = lord
    hit.defender_definition = catalog.get("monsters",
        monsters.MONS_PANDEMONIUM_LORD)
    effects.apply(game, flavours.ANTIMAGIC, hit)

    harness.truthy(ctx:has(lord, component.MONSTER_ENFEEBLE),
        "generated Pan lord active spells admit antimagic")

    hit.defender = wizard
    hit.defender_definition = catalog.get("monsters",
        monsters.MONS_ORC_WIZARD)

    local before = ctx:get(wizard,
        component.MONSTER_ENFEEBLE).antimagic_aut

    hit.damage_done = 0
    effects.apply(game, flavours.ANTIMAGIC, hit)

    harness.equal(ctx:get(wizard,
        component.MONSTER_ENFEEBLE).antimagic_aut, before,
        "damageless Antimagic cannot extend the enchantment")

    local vine = fixture.actor(ctx, monsters.MONS_VINE_STALKER,
        83, 20, 100)

    ctx:add(vine, component.MONSTER_ENFEEBLE, {
        weak_aut = 0,
        antimagic_aut = 100,
        blind_aut = 0,
        dazed_aut = 0,
    })

    hit.attacker = vine
    hit.attacker_name = "vine stalker"
    hit.defender = player
    hit.defender_definition = nil
    hit.damage_done = 4

    effects.apply(game, flavours.ANTIMAGIC, hit)

    harness.equal(ctx:get(vine,
        component.MONSTER_ENFEEBLE).antimagic_aut, 96,
        "vine stalker spends its own antimagic duration to invigorate")

    ctx:set(player, component.MAGIC, {
        current = 0,
        max = 20,
    })

    effects.apply(game, flavours.ANTIMAGIC, hit)

    harness.equal(ctx:get(vine,
        component.MONSTER_ENFEEBLE).antimagic_aut, 92,
        "vine stalker invigorates even when player MP is already empty")
end

-- Tests use production source IDs and ECS schemas through the shared fixture.
function test.run(ctx)
    stat_choice(ctx)
    live_stat_contact(ctx)
    player_drain(ctx)
    monster_drain(ctx)
    vampiric(ctx)
    scarab(ctx)
    pain(ctx)
    antimagic(ctx)
end

return test
