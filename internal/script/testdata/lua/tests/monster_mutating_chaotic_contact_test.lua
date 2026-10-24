-- Natural Mutate and Chaos attacks use the same saved actor state as spells
-- and weapon brands. These tests keep source choice rolls separate from HP.
local attacks = require("policy.combat.monster_attack_flavours")
local actions = require("policy.combat.melee_actions")
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local choices = require("policy.combat.chaos_choice")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local flavours = require("constants.attack_flavours")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local ugly_thing = require("policy.monsters.ugly_thing")
local weapon_brands = require("constants.weapon_brands")

local test = {}

-- The physical packet has passed armour before the flavour is considered.
-- HP loss can still differ if a shield or other later effect absorbs it.
local function hit(attacker, defender, definition, physical, dealt)
    return {
        kind = "hit",
        attacker = attacker,
        attacker_name = "chaotic monster",
        defender = defender,
        defender_definition = definition,
        attack_base_damage = 20,
        hit_dice = 8,
        physical_damage = physical,
        damage_done = dealt,
    }
end

-- Mnoleg's one-in-four gate precedes the already shared mutation owner.
-- Maximum player resistance and undead monster bodies retain immunity.
local function mutate_contact(ctx, game, attacker, player)
    local strike = hit(attacker, player, nil, 5, 5)
    local rolls = 0

    function game:random(_, bound)
        if bound == 4 then
            rolls = rolls + 1
            return 1
        end

        return 0
    end

    harness.falsy(attacks.apply(game, flavours.MUTATE, strike),
        "failed mutagenic chance changes no player mutation")
    harness.equal(#records.list(ctx, player), 0,
        "failed mutagenic chance leaves mutation records empty")

    strike.physical_damage = 0
    harness.falsy(attacks.apply(game, flavours.MUTATE, strike),
        "zero post-armour damage cannot trigger mutation")
    harness.equal(rolls, 1,
        "zero physical damage consumes no mutation chance")
    strike.physical_damage = 5

    function game:random()
        return 0
    end

    harness.truthy(attacks.apply(game, flavours.MUTATE, strike),
        "successful mutagenic player contact reaches mutation owner")
    harness.truthy(#records.list(ctx, player) > 0,
        "player gains a saved mutation record")

    local resistant = fixture.actor(ctx, monsters.MONS_HUMAN,
        12, 10, 100)

    ctx:add(resistant, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    records.grant_acquired(ctx, resistant,
        mutations.MUT_MUTATION_RESISTANCE, 3)
    attacks.apply(game, flavours.MUTATE,
        hit(attacker, resistant, nil, 5, 5))
    harness.equal(#records.list(ctx, resistant), 1,
        "maximum mutation resistance rejects the new record")

    local wraith = fixture.actor(ctx, monsters.MONS_WRAITH,
        13, 10, 100)

    harness.falsy(attacks.apply(game, flavours.MUTATE,
        hit(attacker, wraith, catalog.get("monsters",
            monsters.MONS_WRAITH), 5, 5)),
        "undead monster cannot be malmutated")
    harness.falsy(ctx:has(wraith, component.WRETCHED),
        "immune monster has no saved Wretched state")

    local orc = fixture.actor(ctx, monsters.MONS_ORC,
        14, 10, 100)

    harness.truthy(attacks.apply(game, flavours.MUTATE,
        hit(attacker, orc, catalog.get("monsters",
            monsters.MONS_ORC), 5, 5)),
        "natural monster contact reaches monster malmutation owner")
    harness.truthy(ctx:has(orc, component.WRETCHED),
        "mutable monster gains saved Wretched state")

    local ugly = fixture.actor(ctx, monsters.MONS_UGLY_THING,
        15, 10, 100)
    local ugly_definition = catalog.get("monsters",
        monsters.MONS_UGLY_THING)

    ctx:add(ugly, component.UGLY_THING,
        ugly_thing.roll(game, ugly_definition))

    local mutated_on_own_stream = false

    function game:random(stream, bound)
        if stream == streams.MUTATION then
            mutated_on_own_stream = true
        end

        return 0
    end

    harness.truthy(attacks.apply(game, flavours.MUTATE,
        hit(attacker, ugly, ugly_definition, 5, 5)),
        "mutable ugly thing rerolls through its live trait owner")
    harness.truthy(mutated_on_own_stream,
        "ugly thing traits consume mutation rather than melee randomness")
end

-- The source pool filters by current defender rather than leaving inert
-- outcomes in a fixed 74-weight draw. Player and monster bodies differ.
local function weighted_choices(ctx, game, player)
    local orc = fixture.actor(ctx, monsters.MONS_ORC,
        20, 10, 100)
    local wraith = fixture.actor(ctx, monsters.MONS_WRAITH,
        21, 10, 100)
    local bound

    function game:random(_, size)
        bound = size
        return 0
    end

    harness.equal(choices.choose(game, {
        defender = orc,
        definition = catalog.get("monsters", monsters.MONS_ORC),
    }), weapon_brands.FLAMING,
        "first eligible chaos band is Fire")
    harness.equal(bound, 64,
        "natural Orc excludes Holy and Antimagic before draw")

    choices.choose(game, {
        defender = wraith,
        definition = catalog.get("monsters", monsters.MONS_WRAITH),
    })
    harness.equal(bound, 49,
        "undead Wraith excludes venom and life theft but admits Holy")

    choices.choose(game, { defender = player })
    harness.equal(bound, 69,
        "natural player admits Antimagic but excludes Holy")

    ctx:set(player, component.PLAYER, {
        species_id = species.SP_MUMMY,
    })
    choices.choose(game, { defender = player })
    harness.equal(bound, 54,
        "undead player admits Holy but excludes life theft and venom")
    ctx:set(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    return orc
end

-- Ordinary chaos outcomes use natural flavour formulas; choosing Chaos
-- itself enters the existing inner actor-effect table once.
local function chaotic_contact(ctx, game, attacker, orc)
    local strike = hit(attacker, orc,
        catalog.get("monsters", monsters.MONS_ORC), 5, 5)

    function game:random()
        return 0
    end

    harness.truthy(attacks.apply(game, flavours.CHAOTIC, strike),
        "chaotic hit chooses and applies the source Fire flavour")
    harness.truthy(ctx:get(orc, component.HEALTH).current < 100,
        "source Fire flavour deals its independent elemental packet")

    local inner = fixture.actor(ctx, monsters.MONS_ORC,
        30, 10, 100)
    local inner_hit = hit(attacker, inner,
        catalog.get("monsters", monsters.MONS_ORC), 5, 5)
    local draws = 0

    function game:random(_, bound)
        draws = draws + 1

        if draws == 1 then
            return 40
        end

        if draws == 2 then
            return 19
        end

        return 0
    end

    harness.truthy(attacks.apply(game, flavours.CHAOTIC, inner_hit),
        "self-selected Chaos enters the inner actor-effect table")
    harness.truthy(ctx:has(inner, component.MONSTER_BOONS),
        "inner Chaos grants the selected saved Might boon")
    harness.equal(draws, 2,
        "chaos makes one outer and one inner weighted draw")

    local dry = hit(attacker, inner,
        catalog.get("monsters", monsters.MONS_ORC), 0, 0)

    draws = 0
    harness.falsy(attacks.apply(game, flavours.CHAOTIC, dry),
        "zero post-armour damage cannot draw chaos")
    harness.equal(draws, 0,
        "zero-damage hit consumes no chaos outcome roll")
end

-- Natural Chaos can select Venom against a living player. The ordinary
-- Poison flavour must share that path so neither applies poison twice.
local function player_poison_contact(ctx, game, attacker, player)
    local strike = hit(attacker, player, nil, 5, 5)
    local draws = 0

    function game:random(_, bound)
        draws = draws + 1

        if draws == 1 then
            return 30
        end

        return 0
    end

    harness.truthy(attacks.apply(game, flavours.CHAOTIC, strike),
        "natural Chaos Venom poisons a living player")
    harness.truthy(ctx:get(player, component.POISON).amount_scaled > 0,
        "chaos Venom writes the ordinary saved player poison")

    ctx:remove(player, component.POISON)

    function game:random()
        return 0
    end

    harness.truthy(attacks.apply(game, flavours.POISON, strike),
        "ordinary monster Poison uses the same player contact owner")
    harness.truthy(ctx:get(player, component.POISON).amount_scaled > 0,
        "ordinary Poison reaches the saved player status")

    local immune = fixture.actor(ctx, monsters.MONS_HUMAN,
        32, 10, 100)

    ctx:add(immune, component.PLAYER, {
        species_id = species.SP_GARGOYLE,
    })

    game.player_entity = immune

    harness.falsy(attacks.apply(game, flavours.POISON,
        hit(attacker, immune, nil, 5, 5)),
        "natural poison respects innate rPois 3")
    harness.falsy(ctx:has(immune, component.POISON),
        "immune player stores no poison exposure")

    game.player_entity = player
end

-- Catalog attack slots must reach these policies through an actual melee
-- round. Durable allied targets survive Mnoleg's earlier plain claw and
-- expose Chaos Spawn's selected poison as a saved ECS status.
local function live_contacts(ctx, game)
    local mnoleg = fixture.actor(ctx, monsters.MONS_MNOLEG,
        40, 40, 1000)
    local mutating_target = fixture.actor(ctx, monsters.MONS_ORC,
        41, 40, 1000)

    ctx:add(mutating_target, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })

    function game:random(_, bound)
        if bound == 4 then
            return 0
        end

        return bound - 1
    end

    actions.monster_target(game, mnoleg, mutating_target)

    harness.truthy(ctx:has(mutating_target, component.WRETCHED),
        "live Mnoleg tentacle applies its Mutate flavour")

    local chaos_spawn = fixture.actor(ctx, monsters.MONS_CHAOS_SPAWN,
        50, 40, 1000)
    local poisoned_target = fixture.actor(ctx, monsters.MONS_ORC,
        51, 40, 1000)

    ctx:add(poisoned_target, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })

    function game:random(_, bound)
        if bound == 64 then
            return 30
        end

        if bound == 3 then
            return 0
        end

        return bound - 1
    end

    actions.monster_target(game, chaos_spawn, poisoned_target)

    harness.truthy(ctx:has(poisoned_target,
        component.PROJECTILE_POISON),
        "live Chaos Spawn Venom writes monster poison")
end

-- A real player defense and HP owner must also route catalog contact into
-- mutation and poison. This catches the separate player melee entry path.
local function live_player_contacts(ctx, game)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        61, 40, 1000)
    local chaos_spawn = fixture.actor(ctx, monsters.MONS_CHAOS_SPAWN,
        60, 40, 1000)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Contact player",
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

    game.player_entity = player

    function game:random(_, bound)
        if bound == 69 then
            return 30
        end

        if bound == 3 then
            return 0
        end

        return bound - 1
    end

    actions.monster(game, chaos_spawn)

    harness.truthy(ctx:has(player, component.POISON),
        "live Chaos Spawn Venom writes player poison")

    local mnoleg = fixture.actor(ctx, monsters.MONS_MNOLEG,
        60, 41, 1000)

    function game:random(_, bound)
        if bound == 4 then
            return 0
        end

        return bound - 1
    end

    actions.monster(game, mnoleg)

    harness.truthy(#records.list(ctx, player) > 0,
        "live Mnoleg tentacle records player malmutation")
end

-- Production schemas and catalogs are loaded by the Lua rule runner.
function test.run(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_MNOLEG,
        10, 10, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        11, 10, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local game = fixture.context(ctx, player)

    mutate_contact(ctx, game, attacker, player)
    local orc = weighted_choices(ctx, game, player)
    chaotic_contact(ctx, game, attacker, orc)
    player_poison_contact(ctx, game, attacker, player)
    live_contacts(ctx, game)
    live_player_contacts(ctx, game)
end

return test
