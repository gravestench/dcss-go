-- Broodmother's bite shares the Summon Spiders roster but owns a wound
-- anchor and native monster provenance. These tests use production ECS.
local actions = require("policy.combat.melee_actions")
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local flavours = require("constants.attack_flavours")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local save_summons = require("policy.save.summons")
local species = require("ids.species")
local spider = require("policy.combat.monster_summons.spiders")
local strikes = require("policy.combat.monster_attack_flavours")
local streams = require("constants.rng_streams")

local test = {}

-- Count only offspring owned by this attacker so earlier test actors
-- cannot make an empty or failed contact look successful.
local function offspring(ctx, attacker)
    local found = {}

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local state = ctx:get(entity, component.SUMMON)

        if state.owner == attacker then
            found[#found + 1] = entity
        end
    end

    return found
end

-- The real roster must keep each contiguous source weight band. The bite
-- uses 10 HD, so its 120 power gives the Wolf Spider a final weight of 60.
local function roster_weights(game)
    local selected = {
        {
            draw = 0,
            kind = monsters.MONS_REDBACK,
        },
        {
            draw = 100,
            kind = monsters.MONS_JUMPING_SPIDER,
        },
        {
            draw = 200,
            kind = monsters.MONS_TARANTELLA,
        },
        {
            draw = 275,
            kind = monsters.MONS_CULICIVORA,
        },
        {
            draw = 325,
            kind = monsters.MONS_ORB_SPIDER,
        },
        {
            draw = 375,
            kind = monsters.MONS_WOLF_SPIDER,
        },
    }

    for _, case in ipairs(selected) do
        local bound

        function game:random(stream, size)
            harness.equal(stream, streams.MONSTER_SPELL,
                "spider kind belongs to summon randomness")
            bound = size

            return case.draw
        end

        harness.equal(spider.pick(game, 120), case.kind,
            "source spider weight band selects its named kind")
        harness.equal(bound, 435,
            "source 10 HD bite has 435 total spider weight")
    end
end

-- A natural hit uses its own one-in-three gate and cannot create a
-- summon after armour leaves no damaging wound.
local function contact_gates(ctx, game, attacker, player)
    local strike = {
        kind = "hit",
        attacker = attacker,
        defender = player,
        hit_dice = 10,
        physical_damage = 6,
        damage_done = 6,
    }
    local chance_rolls = 0

    function game:random(stream, bound)
        if stream == streams.MELEE and bound == 3 then
            chance_rolls = chance_rolls + 1

            return 1
        end

        return 0
    end

    harness.falsy(strikes.apply(game, flavours.SPIDER, strike),
        "failed wound chance summons nothing")
    harness.equal(#offspring(ctx, attacker), 0,
        "failed wound has no hidden offspring")

    strike.physical_damage = 0
    harness.falsy(strikes.apply(game, flavours.SPIDER, strike),
        "zero post-armour damage cannot summon")
    harness.equal(chance_rolls, 1,
        "zero physical damage consumes no chance roll")

    strike.physical_damage = 6
    strike.kind = "dodge"
    harness.falsy(strikes.apply(game, flavours.SPIDER, strike),
        "dodged bite cannot enter the Spider contact owner")
    harness.equal(chance_rolls, 1,
        "dodged bite consumes no chance roll")

    strike.kind = "hit"

    function game:random()
        return 0
    end

    harness.truthy(strikes.apply(game, flavours.SPIDER, strike),
        "successful bite creates one spider")
    harness.equal(#offspring(ctx, attacker), 1,
        "one contact creates at most one offspring")

    return offspring(ctx, attacker)[1]
end

-- The wound is the anchor, while the attacker remains the owner. Saved
-- provenance names the source monster instead of a fictitious spell.
local function native_record(ctx, game, attacker, victim, child)
    local state = ctx:get(child, component.SUMMON)
    local position = ctx:get(child, component.POSITION)
    local wound = ctx:get(victim, component.POSITION)
    local actor = ctx:get(child, component.ACTOR)
    local original_kind = actor.kind_id
    local ai = ctx:get(child, component.AI)

    harness.equal(state.owner, attacker,
        "Broodmother owns its offspring")
    harness.equal(state.source_category, categories.MONSTERS,
        "native bite is attributed to a monster")
    harness.equal(state.source_id, monsters.MONS_BROODMOTHER,
        "summon source names Broodmother")
    harness.truthy(state.expires_aut > 0,
        "degree-three offspring has a saved expiry")
    harness.truthy(math.max(math.abs(position.x - wound.x),
        math.abs(position.y - wound.y)) == 1,
        "offspring appears beside the wounded actor")
    harness.truthy(spider.contains(actor.kind_id),
        "offspring comes from the shared source roster")

    save_summons.validate(game, child, actor, position,
        ai, state, 0)

    state.source_id = monsters.MONS_ORC
    ctx:set(child, component.SUMMON, state)

    local valid = pcall(save_summons.validate,
        game, child, actor, position, ai, state, 0)

    harness.falsy(valid,
        "restore rejects a forged non-Spider monster origin")

    state.source_id = monsters.MONS_BROODMOTHER
    ctx:set(child, component.SUMMON, state)

    actor.kind_id = monsters.MONS_RAT
    ctx:set(child, component.ACTOR, actor)

    valid = pcall(save_summons.validate,
        game, child, actor, position, ai, state, 0)

    harness.falsy(valid,
        "restore rejects a forged non-spider child species")

    actor.kind_id = original_kind
    ctx:set(child, component.ACTOR, actor)

    local unrelated = fixture.actor(ctx, monsters.MONS_ORC,
        20, 20, 100)

    state.owner = unrelated
    ctx:set(child, component.SUMMON, state)

    valid = pcall(save_summons.validate,
        game, child, actor, position, ai, state, 0)

    harness.falsy(valid,
        "restore rejects an unrelated monster claiming Broodmother birth")

    state.owner = victim
    ctx:set(child, component.SUMMON, state)

    valid = pcall(save_summons.validate,
        game, child, actor, position, ai, state, 0)

    harness.falsy(valid,
        "restore rejects a player claiming native Broodmother birth")

    state.owner = attacker
    ctx:set(child, component.SUMMON, state)

    local owner = ctx:get(attacker, component.ACTOR)

    owner.kind_id = monsters.MONS_ORC
    ctx:set(attacker, component.ACTOR, owner)
    ctx:add(attacker, component.MONSTER_POLYMORPH, {
        original_kind_id = monsters.MONS_BROODMOTHER,
    })

    save_summons.validate(game, child, actor, position,
        ai, state, 0)

    owner.kind_id = monsters.MONS_BROODMOTHER
    ctx:set(attacker, component.ACTOR, owner)
    ctx:remove(attacker, component.MONSTER_POLYMORPH)
end

-- All eight neighboring cells can be blocked, but a successful contact
-- must then emit no birth message and leave no ECS child behind.
local function blocked_wound(ctx, game)
    local attacker = fixture.actor(ctx, monsters.MONS_BROODMOTHER,
        30, 30, 100)
    local victim = fixture.actor(ctx, monsters.MONS_ORC,
        31, 30, 100)
    local messages = {}

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                game.walls[(31 + dx) .. ":" .. (30 + dy)] = true
            end
        end
    end

    function game:random()
        return 0
    end

    function game:emit(_, message)
        messages[#messages + 1] = message
    end

    local applied = strikes.apply(game, flavours.SPIDER, {
        kind = "hit",
        attacker = attacker,
        defender = victim,
        defender_definition = catalog.get("monsters", monsters.MONS_ORC),
        hit_dice = 10,
        physical_damage = 5,
        damage_done = 5,
    })

    harness.falsy(applied,
        "blocked wound cannot create a spider")
    harness.equal(#offspring(ctx, attacker), 0,
        "blocked wound leaves no summon record")
    harness.equal(#messages, 0,
        "failed placement announces no spider birth")

    game.walls = {}
end

-- A real Broodmother attack must route the catalog Spider flavour
-- through ordinary melee before creating the same saved child.
local function live_contact(ctx, game)
    local attacker = fixture.actor(ctx, monsters.MONS_BROODMOTHER,
        50, 40, 1000)
    local victim = fixture.actor(ctx, monsters.MONS_ORC,
        51, 40, 1000)

    ctx:add(victim, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })

    function game:random(_, bound)
        if bound == 3 then
            return 0
        end

        return bound - 1
    end

    actions.monster_target(game, attacker, victim)

    harness.equal(#offspring(ctx, attacker), 1,
        "live Broodmother bite creates one saved spider")
end

-- Player defense takes a separate melee entry path. A real successful
-- Broodmother bite there must still anchor the spider to the player wound.
local function live_player_contact(ctx, game)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        61, 40, 1000)
    local attacker = fixture.actor(ctx, monsters.MONS_BROODMOTHER,
        60, 40, 1000)

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

    game.player_entity = player

    function game:random(_, bound)
        if bound == 3 then
            return 0
        end

        return bound - 1
    end

    actions.monster(game, attacker)

    local children = offspring(ctx, attacker)

    harness.truthy(ctx:get(player, component.HEALTH).current < 1000,
        "live bite wounds the player before spawning")
    harness.equal(#children, 1,
        "live Broodmother bite against player creates one spider")

    local wound = ctx:get(player, component.POSITION)
    local birth = ctx:get(children[1], component.POSITION)
    local state = ctx:get(children[1], component.SUMMON)

    harness.truthy(math.max(math.abs(birth.x - wound.x),
        math.abs(birth.y - wound.y)) == 1,
        "live player wound anchors the spider")
    harness.equal(state.owner, attacker,
        "live player wound keeps Broodmother ownership")
    harness.equal(state.source_category, categories.MONSTERS,
        "live player wound records native monster provenance")
end

-- The rule runner loads the actual catalog, schemas, melee owner, and
-- common summon factory; the test supplies only actors and random draws.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        11, 10, 100)
    local attacker = fixture.actor(ctx, monsters.MONS_BROODMOTHER,
        10, 10, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })

    local game = fixture.context(ctx, player)

    roster_weights(game)
    local child = contact_gates(ctx, game, attacker, player)
    native_record(ctx, game, attacker, player, child)
    blocked_wound(ctx, game)
    live_contact(ctx, game)
    live_player_contact(ctx, game)
end

return test
