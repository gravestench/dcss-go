-- Trample displaces first and follows only after the attack's reactions.
-- Source: melee-attack.cc:do_knockback and fineff.cc:trample_follow.
local component = require("constants.component")
local actions = require("policy.combat.melee_actions")
local attack_types = require("constants.monster_attack_types")
local fixture = require("tests.monster_ally_support_fixture")
local flavours = require("policy.combat.monster_attack_flavours")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local pan_lord = require("policy.population.pan_lord")
local species = require("ids.species")
local terrain = require("constants.terrain")
local traps = require("ids.traps")
local traits = require("constants.pan_lord_traits")
local trample = require("policy.combat.trample")
local weapon_brands = require("constants.weapon_brands")

local test = {}

-- Give every case real ECS positions and the same deterministic melee roll.
local function scene(ctx, x)
    local lord = fixture.actor(ctx,
        monsters.MONS_PANDEMONIUM_LORD, x, 30, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, x + 1, 30, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local game = fixture.context(ctx, player)

    -- Force the source size contest to succeed without copying its formula.
    function game:random(_, bound)
        return 0
    end

    return game, lord, player
end

-- The follow-up is a final effect. A reaction that kills or moves the lord
-- after the push must not cause it to occupy the vacated cell.
local function check_delayed_follow(ctx)
    local game, lord, player = scene(ctx, 10)
    local hit = {
        kind = "hit",
        attacker = lord,
        defender = player,
    }

    harness.truthy(flavours.apply(game, traits.trample, hit),
        "open floor allows trample")
    harness.equal(ctx:get(player, component.POSITION).x, 12,
        "defender is pushed first")
    harness.equal(ctx:get(lord, component.POSITION).x, 10,
        "attacker waits for the final effect")

    trample.follow(game, hit)
    harness.equal(ctx:get(lord, component.POSITION).x, 11,
        "living adjacent attacker follows into the vacated cell")

    local next_game, next_lord = scene(ctx, 20)
    local next_hit = {
        kind = "hit",
        attacker = next_lord,
        defender = next_game:player(),
    }

    harness.truthy(flavours.apply(next_game, traits.trample, next_hit),
        "second push succeeds")
    ctx:set(next_lord, component.HEALTH, {
        current = 0,
        max = 100,
    })
    trample.follow(next_game, next_hit)

    harness.equal(ctx:get(next_lord, component.POSITION).x, 20,
        "a dead attacker cannot follow")

    local moving_game, moving_lord, moving_player = scene(ctx, 80)
    local moving_hit = {
        kind = "hit",
        attacker = moving_lord,
        defender = moving_player,
        player_moving = true,
    }

    harness.falsy(flavours.apply(moving_game, traits.trample,
        moving_hit), "opportunity contact cannot trample a moving player")
    harness.equal(ctx:get(moving_player, component.POSITION).x, 81,
        "moving player keeps the original square")

    local shifted_game, shifted_lord = scene(ctx, 90)
    local shifted_hit = {
        kind = "hit",
        attacker = shifted_lord,
        defender = shifted_game:player(),
    }

    harness.truthy(flavours.apply(shifted_game,
        traits.trample, shifted_hit), "third shove succeeds")
    shifted_game:move_actor(shifted_lord, 1, 90, 32)
    trample.follow(shifted_game, shifted_hit)

    harness.equal(ctx:get(shifted_lord, component.POSITION).y, 32,
        "an attacker moved away by a reaction cannot follow")
end

-- Flight only makes dangerous terrain habitable while it is reliable.
-- Source warns against an expiring flight over deep water or lava.
local function check_dangerous_destination(ctx)
    local game, lord, player = scene(ctx, 30)
    local hit = {
        kind = "hit",
        attacker = lord,
        defender = player,
    }

    game.cells["32:30"] = terrain.DNGN_LAVA
    harness.falsy(flavours.apply(game, traits.trample, hit),
        "grounded player cannot be trampled into lava")

    ctx:add(player, component.ZAP_FLIGHT, {
        remaining_aut = 50,
    })
    harness.falsy(flavours.apply(game, traits.trample, hit),
        "expiring flight cannot carry a trampled player into lava")

    ctx:set(player, component.ZAP_FLIGHT, {
        remaining_aut = 200,
    })
    harness.truthy(flavours.apply(game, traits.trample, hit),
        "stable flight permits the hazardous landing")

    local water_game, water_lord, swimmer = scene(ctx, 70)
    local water_hit = {
        kind = "hit",
        attacker = water_lord,
        defender = swimmer,
    }

    water_game.cells["72:30"] = terrain.DNGN_DEEP_WATER
    harness.falsy(flavours.apply(water_game, traits.trample, water_hit),
        "grounded human cannot be trampled into deep water")

    ctx:set(swimmer, component.PLAYER, {
        species_id = species.SP_MERFOLK,
    })
    harness.truthy(flavours.apply(water_game, traits.trample, water_hit),
        "a swimming species can enter deep water without flight")
end

-- Source cannot move a constricted defender or follow with an attacker
-- disabled before the shove. These guards precede any position mutation.
local function check_immobility(ctx)
    local game, lord, player = scene(ctx, 40)
    local hit = {
        kind = "hit",
        attacker = lord,
        defender = player,
    }

    ctx:add(lord, component.PARALYSIS, {
        remaining_aut = 10,
    })
    harness.falsy(flavours.apply(game, traits.trample, hit),
        "paralyzed attacker cannot shove")
    harness.equal(ctx:get(player, component.POSITION).x, 41,
        "immobilization leaves target in place")

    local held_game, held_lord = scene(ctx, 60)
    local held_monster = fixture.actor(ctx, monsters.MONS_ORC, 61, 30, 100)
    local draws = 0

    ctx:add(held_monster, component.PLAYER_CONSTRICTION, {
        by = held_game:player(),
    })

    -- Count the contested roll before the source constriction guard.
    function held_game:random(_, bound)
        draws = draws + 1

        return 0
    end

    local held_hit = {
        kind = "hit",
        attacker = held_lord,
        defender = held_monster,
    }

    harness.falsy(flavours.apply(held_game, traits.trample, held_hit),
        "a constricted monster cannot be shoved")
    harness.equal(draws, 1,
        "source size roll precedes the constriction guard")
end

-- Forced movement stops an in-progress Passwall delay, as source
-- stop_delay(true) does after moving a player to the new square.
local function check_passwall_interruption(ctx)
    local game, lord, player = scene(ctx, 50)

    ctx:add(player, component.PASSWALL_DELAY, {
        level_id = 1,
        dest_x = 55,
        dest_y = 30,
        started_aut = 0,
        remaining_aut = 30,
    })

    local plate = ctx:create()

    ctx:add(plate, component.WORLD_TRAP, {
        kind_id = traps.TRAP_PLATE,
        level_id = 1,
        x = 52,
        y = 30,
        charges = 0,
        revealed = true,
        source_record = "",
    })

    local plate_events = 0

    -- The production trap calls the signal sink after the forced move.
    function game:signal(name, value)
        if name == "trap.pressure_plate" and value.actor == player then
            plate_events = plate_events + 1
        end
    end

    local moved = flavours.apply(game, traits.trample, {
        kind = "hit",
        attacker = lord,
        defender = player,
    })

    harness.truthy(moved, "trample displaces a Passwall caster")
    harness.falsy(ctx:has(player, component.PASSWALL_DELAY),
        "forced movement interrupts Passwall")
    harness.equal(plate_events, 1,
        "forced movement activates the entered trap")
end

-- A live monster action must resolve the deferred follow itself. Direct
-- flavour tests above prove the two phases; this catches an attack caller
-- that forgets to run the final phase after player reactions.
local function check_live_melee_follow(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 101, 30, 1000)
    local lord = fixture.actor(ctx,
        monsters.MONS_PANDEMONIUM_LORD, 100, 30, 1000)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Trample target",
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

    -- Roll the ordinary generated lord before pinning this attack's trait.
    function game:random(_, bound)
        return bound - 1
    end

    local generated = pan_lord.roll(game, false)

    generated.flavour_id = traits.trample
    generated.attack_type_id = attack_types.TRAMPLE
    generated.brand_id = weapon_brands.NORMAL
    ctx:add(lord, component.PANDEMONIUM_LORD, generated)

    -- Keep normal hit rolls favorable and force the six-sided size contest.
    function game:random(stream, bound)
        if stream == "melee" and bound == 6 then
            return 0
        end

        return bound - 1
    end

    actions.monster(game, lord)

    harness.equal(ctx:get(player, component.POSITION).x, 102,
        "live contact pushes the defender")
    harness.equal(ctx:get(lord, component.POSITION).x, 101,
        "the action resolves its final follow")
end

-- Each case uses production components and the ordinary melee flavour.
function test.run(ctx)
    check_delayed_follow(ctx)
    check_dangerous_destination(ctx)
    check_immobility(ctx)
    check_passwall_interruption(ctx)
    check_live_melee_follow(ctx)
end

return test
