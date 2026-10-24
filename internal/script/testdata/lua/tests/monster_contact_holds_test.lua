-- Contact holds exercise production flavour dispatch and ECS schemas.
-- Sparse positions make eligibility visible without copying the game grid.
local attacks = require("policy.combat.monster_attack_flavours")
local attack_types = require("constants.monster_attack_types")
local catalog = require("policy.catalog")
local component = require("constants.component")
local constriction = require("policy.combat.constriction")
local engulf = require("policy.combat.engulf")
local fixture = require("tests.monster_ally_support_fixture")
local flavours = require("constants.attack_flavours")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local species = require("ids.species")
local constriction_system = require("systems.status_constriction")
local movement_system = require("systems.world_movement")
local intents = require("constants.intent")

local test = {}

-- Source contact effects still run when the physical strike does zero HP
-- damage. The supplied victim is either the player or a monster actor.
local function hit(attacker, victim, definition, attack_type)
    return {
        kind = "hit",
        attacker = attacker,
        attacker_name = "holder",
        defender = victim,
        defender_definition = definition,
        attack_type = attack_type,
        hit_dice = 8,
        damage_done = 0,
    }
end

-- A player and an orc can be held by the same large body, but each victim
-- owns its own status link. The second grab must not replace the first.
local function crush(ctx)
    local snake = fixture.actor(ctx, monsters.MONS_ANACONDA, 10, 10, 100)
    local other_snake = fixture.actor(ctx, monsters.MONS_ANACONDA,
        9, 11, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 11, 10, 100)
    local orc = fixture.actor(ctx, monsters.MONS_ORC, 10, 11, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local game = fixture.context(ctx, player)
    local strike = hit(snake, player, nil, attack_types.CONSTRICT)

    harness.truthy(attacks.apply(game, flavours.CRUSH, strike),
        "zero-damage Crush starts a player grip")
    harness.equal(ctx:get(player, component.CONSTRICTION).by, snake,
        "player grip retains its source")

    strike.attacker = other_snake
    strike.defender = orc
    strike.defender_definition = catalog.get("monsters", monsters.MONS_ORC)

    harness.truthy(attacks.apply(game, flavours.CRUSH, strike),
        "zero-damage Crush starts a monster grip")
    harness.equal(ctx:get(orc, component.CONSTRICTION).by, other_snake,
        "monster grip retains its source")

    ctx:add(orc, component.INTENT, {
        kind = intents.MOVE,
        dx = 1,
        dy = -1,
    })
    movement_system.update(game, orc, 10)
    harness.equal(ctx:get(orc, component.INTENT).kind, intents.MELEE,
        "gripped monster can still strike an adjacent enemy")
    harness.equal(ctx:get(orc, component.CONSTRICTION).escape_attempts,
        0, "attacking does not roll an escape attempt")
    ctx:remove(orc, component.INTENT)

    local jelly = fixture.actor(ctx, monsters.MONS_JELLY,
        9, 12, 100)
    local free_snake = fixture.actor(ctx, monsters.MONS_ANACONDA,
        8, 12, 100)

    strike.attacker = free_snake
    strike.defender = jelly
    strike.defender_definition = catalog.get("monsters",
        monsters.MONS_JELLY)
    harness.falsy(attacks.apply(game, flavours.CRUSH, strike),
        "jelly bodies cannot be gripped")
    harness.falsy(ctx:has(jelly, component.CONSTRICTION),
        "immune target has no saved grip")

    strike.attacker = other_snake
    strike.defender = orc
    strike.defender_definition = catalog.get("monsters",
        monsters.MONS_ORC)

    local before = ctx:get(orc, component.HEALTH).current

    constriction_system.update(game, other_snake, 10)
    harness.equal(ctx:get(orc, component.CONSTRICTION).held_aut, 10,
        "source turn advances the monster's saved grip duration")
    harness.truthy(ctx:get(orc, component.HEALTH).current < before,
        "source turn constricts the monster victim")

    strike.player_moving = true
    ctx:remove(orc, component.CONSTRICTION)
    harness.falsy(attacks.apply(game, flavours.CRUSH, strike),
        "departure contact cannot grab")

    constriction.release_for(game, snake)
    harness.falsy(ctx:has(player, component.CONSTRICTION),
        "dying source releases its player's grip")
end

-- A watery elemental and an ooze use the same hold component, but its
-- substance records the hit-time source for player release messages.
local function engulf_contact(ctx)
    local water = fixture.actor(ctx, monsters.MONS_WATER_ELEMENTAL,
        20, 10, 100)
    local ooze = fixture.actor(ctx, monsters.MONS_QUICKSILVER_OOZE,
        30, 10, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 21, 10, 100)
    local orc = fixture.actor(ctx, monsters.MONS_ORC, 31, 10, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local game = fixture.context(ctx, player)

    function game:random(_, bound)
        return 0
    end

    harness.truthy(attacks.apply(game, flavours.ENGULF,
        hit(water, player, nil, attack_types.HIT)),
        "water elemental engulfs a player after a dry hit")
    harness.equal(ctx:get(player, component.WATER_HOLD).by, water,
        "player water hold retains its source")
    harness.truthy(engulf.silenced(game, player),
        "engulfed breathing player cannot speak")

    ctx:set(player, component.PLAYER, {
        species_id = species.SP_GARGOYLE,
    })
    harness.falsy(engulf.silenced(game, player),
        "unbreathing gargoyle remains able to speak")
    engulf.tick(game, player, 10)
    harness.equal(ctx:get(player, component.WATER_HOLD).elapsed_aut, 10,
        "unbreathing player does not bank drowning time")
    ctx:set(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    harness.truthy(attacks.apply(game, flavours.ENGULF,
        hit(ooze, orc, catalog.get("monsters", monsters.MONS_ORC),
            attack_types.HIT)),
        "ooze engulfs a monster after a dry hit")
    harness.equal(ctx:get(orc, component.WATER_HOLD).by, ooze,
        "monster water hold retains its source")

    local burning = fixture.actor(ctx, monsters.MONS_ORC,
        20, 11, 100)

    ctx:add(burning, component.STICKY_FLAME, {
        degree = 1,
        remaining_aut = 10,
        max_aut = 10,
        source = ooze,
    })

    function game:random(_, bound)
        return bound == 3 and 2 or 0
    end

    harness.falsy(attacks.apply(game, flavours.ENGULF,
        hit(water, burning, catalog.get("monsters", monsters.MONS_ORC),
            attack_types.HIT)),
        "failed engulf chance does not create a hold")
    harness.falsy(ctx:has(burning, component.STICKY_FLAME),
        "failed hold chance still exposes victim to water")

    local dry = hit(ooze, orc,
        catalog.get("monsters", monsters.MONS_ORC),
        attack_types.HIT)

    dry.player_moving = true
    harness.falsy(attacks.apply(game, flavours.ENGULF, dry),
        "departure contact cannot start a new engulf hold")

    local before = ctx:get(orc, component.HEALTH).current
    local actor = ctx:get(orc, component.ACTOR)

    actor.speed = 16
    ctx:set(orc, component.ACTOR, actor)

    local speed_draws = 0

    function game:random(_, bound)
        if bound == 16 then
            speed_draws = speed_draws + 1
        end

        return 0
    end

    engulf.tick(game, orc, 10)
    harness.truthy(ctx:get(orc, component.HEALTH).current < before,
        "engulfed monster loses air on its active turn")
    harness.equal(speed_draws, 2,
        "water hold rounds duration and injury clocks separately")

    game.base:set(orc, component.POSITION, {
        level_id = 1,
        x = 40,
        y = 10,
    })
    engulf.release_far_all(game)
    harness.falsy(ctx:has(orc, component.WATER_HOLD),
        "separation clears a monster hold")

    local water_health = ctx:get(water, component.HEALTH)

    water_health.current = 0
    ctx:set(water, component.HEALTH, water_health)
    engulf.release_for(game, water)
    harness.falsy(ctx:has(player, component.WATER_HOLD),
        "dying water elemental releases its player's hold")
end

-- The Lua rule runner supplies real production schemas and catalog data.
function test.run(ctx)
    crush(ctx)
    engulf_contact(ctx)
end

return test
