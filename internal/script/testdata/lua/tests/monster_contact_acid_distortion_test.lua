-- Acid and distortion belong to the resolved monster attack flavour.
-- Source Tongue and Rift share these effects with Acid and Distort; their
-- longer range changes contact geometry, not the effect after a hit.
local catalog = require("policy.catalog")
local actions = require("policy.combat.melee_actions")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local flavours = require("constants.attack_flavours")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local jobs = require("ids.jobs")
local policy = require("policy.combat.monster_attack_flavours")
local species = require("ids.species")

local test = {}

-- Build a resolved contact with the same fields the melee coordinator
-- supplies. The production ECS health component remains authoritative.
local function contact(attacker, defender, target_definition)
    return {
        kind = "hit",
        attacker = attacker,
        attacker_name = "goliath frog",
        defender = defender,
        defender_definition = target_definition,
        hit_dice = 8,
        damage_done = 4,
        player_credit = false,
    }
end

-- Zero RNG draws make the acid dice their minimum and select the first
-- distortion outcome. A missed or damageless strike must make no draw.
local function first_outcome(game)
    function game:random(_, bound)
        harness.truthy(bound > 0, "contact draw has a positive bound")

        return 0
    end
end

-- Acid splash must treat a reaching tongue exactly like an ordinary acid
-- attack against the player, including the saved corrosion component.
local function player_acid(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_GOLIATH_FROG,
        10, 10, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        12, 10, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local game = fixture.context(ctx, player)
    local hit = contact(attacker, player)

    first_outcome(game)
    policy.apply(game, flavours.REACH_TONGUE, hit)

    harness.equal(ctx:get(player, component.HEALTH).current, 96,
        "Tongue splashes the player for minimum 4d3 acid")
    harness.truthy(ctx:has(player, component.CORROSION),
        "Tongue uses the saved player acid-corrosion owner")
end

-- Monster acid splash retains its separate 2d4 damage packet. The source
-- damage gate applies to both ordinary Acid and its Tongue alias.
local function monster_acid(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_GOLIATH_FROG,
        20, 10, 100)
    local target = fixture.actor(ctx, monsters.MONS_ORC,
        22, 10, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        24, 10, 100)
    local definition = catalog.get("monsters", monsters.MONS_ORC)
    local game = fixture.context(ctx, player)
    local hit = contact(attacker, target, definition)

    first_outcome(game)
    policy.apply(game, flavours.REACH_TONGUE, hit)

    harness.equal(ctx:get(target, component.HEALTH).current, 98,
        "Tongue splashes a monster for minimum 2d4 acid")

    hit.damage_done = 0
    policy.apply(game, flavours.ACID, hit)

    harness.equal(ctx:get(target, component.HEALTH).current, 98,
        "damageless Acid cannot trigger another splash")
end

-- Both distortion flavours use the shared weighted spatial-damage rule.
-- A moving player excludes the blink and banish bands from that draw.
local function player_distortion(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_STARFLOWER,
        30, 10, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        33, 10, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local game = fixture.context(ctx, player)
    local hit = contact(attacker, player)

    first_outcome(game)
    policy.apply(game, flavours.RIFT, hit)

    harness.equal(ctx:get(player, component.HEALTH).current, 99,
        "Rift applies minimum small-warp damage")

    hit.kind = "miss"
    policy.apply(game, flavours.DISTORT, hit)

    hit.kind = "hit"
    hit.damage_done = 0
    policy.apply(game, flavours.DISTORT, hit)

    harness.equal(ctx:get(player, component.HEALTH).current, 99,
        "misses and damageless Distort leave player health unchanged")

    hit.damage_done = 4
    hit.player_moving = true

    function game:random(_, bound)
        harness.equal(bound, 75,
            "movement contact excludes distortion relocation")

        return 74
    end

    policy.apply(game, flavours.DISTORT, hit)

    harness.equal(ctx:get(player, component.POSITION).x, 33,
        "moving player stays in the original cell")
end

-- Distortion of a monster uses the same damage and relocation owners as
-- the weapon brand. Rift and ordinary Distort must not diverge here.
local function monster_distortion(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_STARFLOWER,
        40, 10, 100)
    local target = fixture.actor(ctx, monsters.MONS_ORC,
        43, 10, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        46, 10, 100)
    local definition = catalog.get("monsters", monsters.MONS_ORC)
    local game = fixture.context(ctx, player)
    local hit = contact(attacker, target, definition)

    first_outcome(game)
    policy.apply(game, flavours.DISTORT, hit)

    harness.equal(ctx:get(target, component.HEALTH).current, 99,
        "Distort applies small-warp damage to a monster")

    function game:random(_, bound)
        if bound == 100 then
            return 70
        end

        return bound - 1
    end

    policy.apply(game, flavours.RIFT, hit)

    harness.equal(ctx:get(target, component.POSITION).x, 49,
        "Rift blink relocates the saved monster actor")
end

-- A real two-cell Tongue round must carry its source flavour through the
-- reach slot and the ordinary melee coordinator to the acid effect owner.
-- This catches a policy that works when called directly but is never used
-- by the live monster action.
local function live_tongue(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_GOLIATH_FROG,
        70, 30, 1000)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        72, 30, 1000)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Tongue target",
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

    local original = policy.apply
    local seen_tongue = false

    policy.apply = function(current, flavour_id, hit)
        if flavour_id == flavours.REACH_TONGUE then
            seen_tongue = true
        end

        return original(current, flavour_id, hit)
    end

    actions.monster(game, attacker)
    policy.apply = original

    harness.truthy(seen_tongue,
        "live two-cell round resolves its Tongue flavour")
    harness.truthy(ctx:get(player, component.HEALTH).current < 1000,
        "live two-cell Tongue round damages the player")
end

-- Each case uses the production schemas, effect owners, and source IDs.
function test.run(ctx)
    player_acid(ctx)
    monster_acid(ctx)
    player_distortion(ctx)
    monster_distortion(ctx)
    live_tongue(ctx)
end

return test
