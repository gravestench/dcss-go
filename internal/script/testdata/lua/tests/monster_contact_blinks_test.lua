-- Monster melee blink tests use the production dispatcher, displacement
-- owners, actor schemas, and catalog IDs. Only the floor grid is sparse.
local attacks = require("policy.combat.monster_attack_flavours")
local actions = require("policy.combat.melee_actions")
local blinks = require("policy.combat.monster_attack_flavours.blinks")
local catalog = require("policy.catalog")
local component = require("constants.component")
local vault_effects = require("constants.vault_effects")
local vault_properties = require("constants.vault_properties")
local fixture = require("tests.monster_ally_support_fixture")
local flavours = require("constants.attack_flavours")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local jobs = require("ids.jobs")
local species = require("ids.species")

local test = {}

-- Give ordinary blink one deterministic distant destination. Other
-- draws still exercise the production melee and relocation policies.
local function context(ctx, player)
    local game = fixture.context(ctx, player)
    local coordinate = 0

    function game:random(_, bound)
        if bound == 13 then
            coordinate = coordinate + 1

            return coordinate % 2 == 1 and 8 or 6
        end

        if bound == 2 then
            return 1
        end

        return 0
    end

    return game
end

-- A hit carries a round-owned queue, so two identical contacts do not
-- move anyone until the source final-effect phase.
local function hit(ctx, attacker, defender, pending)
    local actor = ctx:get(defender, component.ACTOR)

    return {
        kind = "hit",
        attacker = attacker,
        defender = defender,
        defender_definition = catalog.get("monsters", actor.kind_id),
        damage_done = 4,
        pending_blinks = pending,
    }
end

-- Blink With moves its source before finding the original victim's
-- adjacent cell; merging the duplicate preserves one displacement.
local function pair(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_MNOLEG,
        10, 10, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        11, 10, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local game = context(ctx, player)
    local pending = {}
    local contact = hit(ctx, attacker, player, pending)

    attacks.apply(game, flavours.BLINK_WITH, contact)
    attacks.apply(game, flavours.BLINK_WITH, contact)

    harness.equal(#pending, 1,
        "matching Blink With contacts merge within one melee round")
    harness.equal(ctx:get(attacker, component.POSITION).x, 10,
        "contact movement waits until the round ends")

    for dx = -1, 1 do
        for dy = -1, 1 do
            local x = 12 + dx
            local y = 10 + dy

            if (x ~= 13 or y ~= 10) and
                (x ~= 12 or y ~= 10) then
                game.walls[x .. ":" .. y] = true
            end
        end
    end

    blinks.resolve(game, pending)

    harness.equal(ctx:get(attacker, component.POSITION).x, 12,
        "Blink With first moves the attacker")
    harness.equal(ctx:get(player, component.POSITION).x, 13,
        "Blink With then places the victim beside the attacker")
end

-- A departure contact skips its chance roll; dead sources and stasis
-- partners are rechecked only when a queued final effect resolves.
local function rejected(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_BLINK_FROG,
        30, 10, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        31, 10, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local game = context(ctx, player)
    local draws = 0
    local pending = {}
    local contact = hit(ctx, attacker, player, pending)

    contact.player_moving = true

    function game:random(_, bound)
        draws = draws + 1

        if bound == 2 then
            return 1
        end

        return 0
    end

    attacks.apply(game, flavours.BLINK, contact)

    harness.equal(draws, 0,
        "departure movement skips the blink chance draw")
    harness.equal(#pending, 0,
        "departure movement schedules no blink")

    contact.player_moving = false
    attacks.apply(game, flavours.BLINK, contact)

    local health = ctx:get(attacker, component.HEALTH)

    health.current = 0
    ctx:set(attacker, component.HEALTH, health)
    blinks.resolve(game, pending)

    harness.equal(ctx:get(attacker, component.POSITION).x, 30,
        "a dead source cannot resolve its queued blink")

    health.current = 100
    ctx:set(attacker, component.HEALTH, health)
    ctx:set(player, component.PLAYER, {
        species_id = species.SP_FORMICID,
    })

    pending = {}
    contact.pending_blinks = pending

    attacks.apply(game, flavours.BLINK_WITH, contact)
    blinks.resolve(game, pending)

    harness.equal(ctx:get(attacker, component.POSITION).x, 30,
        "a stasis partner prevents Blink With before its source moves")

    ctx:set(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    ctx:set(attacker, component.ACTOR, {
        kind_id = monsters.MONS_FORMICID,
        speed = 10,
    })

    pending = {}
    contact.pending_blinks = pending

    attacks.apply(game, flavours.BLINK, contact)
    blinks.resolve(game, pending)

    harness.equal(ctx:get(attacker, component.POSITION).x, 30,
        "intrinsic monster stasis prevents its queued contact blink")

    function game:random(_, bound)
        if bound == 2 then
            return 0
        end

        if bound == 3 then
            return 1
        end

        return 0
    end

    pending = {}
    contact.pending_blinks = pending

    attacks.apply(game, flavours.BLINK, contact)
    attacks.apply(game, flavours.BLINK_WITH, contact)

    harness.equal(#pending, 0,
        "failed blink chance rolls schedule no final effect")
end

-- If the source has a landing but no adjacent partner cell, it still
-- blinks alone. This is a successful attack effect, not a pair swap.
local function no_partner_room(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_PHANTOM,
        50, 10, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        51, 10, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local game = context(ctx, player)
    local pending = {}

    attacks.apply(game, flavours.BLINK_WITH,
        hit(ctx, attacker, player, pending))

    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = 52 + dx
                local y = 10 + dy

                game.walls[x .. ":" .. y] = true
            end
        end
    end

    blinks.resolve(game, pending)

    harness.equal(ctx:get(attacker, component.POSITION).x, 52,
        "source blinks even when its partner has no adjacent space")
    harness.equal(ctx:get(player, component.POSITION).x, 51,
        "blocked partner remains in its original cell")
end

-- A DES no-teleport marker rules out a geometrically open square even
-- when the ordinary monster habitat accepts its terrain.
local function sealed_landing(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_BLINK_FROG,
        60, 10, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        61, 10, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local game = context(ctx, player)
    local pending = {}

    function game:records_at(_, x, y)
        if x == 62 and y == 10 then
            return {
                {
                    kind = vault_effects.PROPERTY,
                    identity = vault_properties.NO_TELE_INTO,
                },
            }
        end

        return {}
    end

    attacks.apply(game, flavours.BLINK,
        hit(ctx, attacker, player, pending))
    blinks.resolve(game, pending)

    harness.equal(ctx:get(attacker, component.POSITION).x, 60,
        "DES no-teleport property rejects the ordinary blink landing")
end

-- Blink With can carry another monster as well as the player. Its
-- landing uses that monster's habitat rather than player terrain rules.
local function monster_partner(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_PHANTOM,
        80, 10, 100)
    local victim = fixture.actor(ctx, monsters.MONS_ORC,
        81, 10, 100)
    local game = context(ctx, fixture.actor(ctx,
        monsters.MONS_HUMAN, 7, 7, 100))
    local pending = {}

    attacks.apply(game, flavours.BLINK_WITH,
        hit(ctx, attacker, victim, pending))

    for dx = -1, 1 do
        for dy = -1, 1 do
            local x = 82 + dx
            local y = 10 + dy

            if (x ~= 83 or y ~= 10) and
                (x ~= 82 or y ~= 10) then
                game.walls[x .. ":" .. y] = true
            end
        end
    end

    blinks.resolve(game, pending)

    harness.equal(ctx:get(attacker, component.POSITION).x, 82,
        "monster Blink With moves the attacker")
    harness.equal(ctx:get(victim, component.POSITION).x, 83,
        "monster Blink With carries its monster victim")
end

-- Real melee needs a full player defense profile. Keep both live tests
-- on the same production components so their hit rolls use the game path.
local function live_player(ctx, x)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        x, 10, 1000)

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

    return player
end

-- A real phantom contact must schedule and finish its movement through
-- the same melee round used by AI, not just a direct policy invocation.
local function live_phantom(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_PHANTOM,
        70, 10, 100)
    local player = live_player(ctx, 71)

    local game = context(ctx, player)
    local coordinate = 0

    function game:random(_, bound)
        if bound == 13 then
            coordinate = coordinate + 1

            return coordinate % 2 == 1 and 8 or 6
        end

        if bound == 2 then
            return 1
        end

        if bound == 3 then
            return 0
        end

        return bound - 1
    end

    actions.monster(game, attacker)

    harness.equal(ctx:get(attacker, component.POSITION).x, 72,
        "live phantom Blink With resolves after its attack round")
end

-- Reorder Mnoleg's four real contact slots for one test. A Blink kick
-- first must leave its three later catalog attacks able to reach the
-- original victim; the definition is restored before other tests run.
local function live_multi_contact(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_MNOLEG,
        90, 10, 1000)
    local player = live_player(ctx, 91)
    local definition = catalog.get("monsters", monsters.MONS_MNOLEG)
    local original = definition.attacks

    definition.attacks = {
        original[4],
        original[1],
        original[2],
        original[3],
    }

    local game = context(ctx, player)
    local coordinate = 0
    local contacts = 0

    function game:random(_, bound)
        if bound == 13 then
            coordinate = coordinate + 1

            return coordinate % 2 == 1 and 9 or 6
        end

        if bound == 3 then
            return 0
        end

        return bound - 1
    end

    function game:emit(channel, message)
        if channel == "combat" and
            string.find(message, "The Mnoleg ", 1, true) == 1 and
            string.find(message, " you", 1, true) then
            contacts = contacts + 1
        end

        self.base:emit(channel, message)
    end

    local ok, failure = pcall(actions.monster, game, attacker)

    definition.attacks = original

    if not ok then
        error(failure)
    end

    harness.equal(contacts, 4,
        "first-slot Blink leaves three later contact slots in range")
    harness.equal(ctx:get(attacker, component.POSITION).x, 93,
        "multi-contact attacker blinks only after its fourth slot")
end

-- Keep test state disjoint so one branch cannot pass by inheriting a
-- position or status from another.
function test.run(ctx)
    pair(ctx)
    rejected(ctx)
    no_partner_room(ctx)
    sealed_landing(ctx)
    monster_partner(ctx)
    live_phantom(ctx)
    live_multi_contact(ctx)
end

return test
