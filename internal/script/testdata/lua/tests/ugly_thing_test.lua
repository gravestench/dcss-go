-- Ugly things own their rolled body traits. Changing one actor must leave
-- its species catalog and a second actor untouched.
local catalog = require("policy.catalog")
local component = require("constants.component")
local factory = require("policy.population.factory")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local malmutation = require("policy.monsters.malmutation")
local attack_flavours = require("policy.combat.monster_attack_flavours")
local flavours = require("constants.attack_flavours")
local monster_profile = require("policy.combat.monster_profile")
local polymorph = require("policy.magic.effects.statuses.polymorph")
local monsters = require("ids.monsters")
local species = require("ids.species")
local resistance = require("constants.resistance_ids")
local streams = require("constants.rng_streams")
local ugly_thing = require("policy.monsters.ugly_thing")
local decision = require("systems.monster_decision")
local view = require("policy.presentation.view")

local test = {}

-- Force only the colour draw. Attack type and HP still pass through the
-- production roller and component schema.
local function world(ctx)
    local game = fixture.observed_context(ctx)
    local colours = 0

    function game:random(stream, bound)
        harness.truthy(bound > 0, "monster draw has a positive bound")

        if stream == streams.MONSTER_TRAITS and bound == 6 then
            local choice = colours % 6
            colours = colours + 1

            return choice
        end

        return 0
    end

    return game
end

-- Elemental colour is a combat effect, not merely a differently coloured
-- glyph. The source adds resisted damage after physical contact and sticky
-- flame starts its normal saved status owner.
local function check_contact_flavours(ctx)
    local game = world(ctx)
    local attacker = factory.spawn(game,
        monsters.MONS_UGLY_THING, 1, 23, 15)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        24, 15, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    game.player_entity = player

    local hit = {
        kind = "hit",
        attacker = attacker,
        defender = player,
        hit_dice = 12,
        damage_done = 1,
    }

    attack_flavours.apply(game, flavours.FIRE, hit)

    harness.equal(ctx:get(player, component.HEALTH).current, 88,
        "fire contact adds HD-scaled damage")

    attack_flavours.apply(game, flavours.ACID, hit)

    harness.truthy(ctx:get(player, component.HEALTH).current < 88,
        "acid contact splashes the defender")

    attack_flavours.apply(game, flavours.STICKY_FLAME, hit)

    harness.truthy(ctx:has(player, component.STICKY_FLAME),
        "sticky flame contact leaves a saved burning status")
end

-- An allied monster's elemental packet can deliver the final HP. Kill
-- credit must reach the same player-kill signal as physical melee damage.
local function check_elemental_kill_credit(ctx)
    local game = world(ctx)
    local attacker = factory.spawn(game,
        monsters.MONS_UGLY_THING, 1, 25, 16)
    local target = factory.spawn(game,
        monsters.MONS_RAT, 1, 26, 16)
    local health = ctx:get(target, component.HEALTH)
    local kills = 0

    health.current = 1
    ctx:set(target, component.HEALTH, health)

    function game:signal(name, entity)
        if name == "player_kill" and entity == target then
            kills = kills + 1
        end
    end

    attack_flavours.apply(game, flavours.FIRE, {
        kind = "hit",
        attacker = attacker,
        defender = target,
        defender_definition = catalog.get("monsters", monsters.MONS_RAT),
        hit_dice = 12,
        damage_done = 1,
        player_credit = true,
    })

    harness.equal(ctx:get(target, component.HEALTH).current, 0,
        "elemental packet can finish a monster")
    harness.equal(kills, 1,
        "allied elemental kill awards player credit exactly once")
end

-- A red ugly thing gets its own fire attack and resistance. A forced
-- purple very ugly thing upgrades its appearance without altering the
-- ordinary catalog definition.
local function check_spawn(ctx)
    local game = world(ctx)
    local ordinary = factory.spawn(game,
        monsters.MONS_UGLY_THING, 1, 15, 15)
    local very = factory.spawn(game,
        monsters.MONS_VERY_UGLY_THING, 1, 16, 15, {
            colour = "purple",
        })
    local species = catalog.get("monsters", monsters.MONS_UGLY_THING)
    local profile = monster_profile.definition(game, ordinary, species)
    local very_profile = monster_profile.definition(game, very,
        catalog.get("monsters", monsters.MONS_VERY_UGLY_THING))
    local visible = view.entity(game, {
        role = "monster",
        kind_id = monsters.MONS_UGLY_THING,
        monster_entity_id = ctx:id(ordinary),
    })

    harness.truthy(component.UGLY_THING,
        "ugly thing has a component key")
    harness.truthy(ctx:get(ordinary, component.UGLY_THING),
        "ordinary ugly thing has saved traits")
    harness.equal(profile.colour_id, "RED", "first source colour")
    harness.equal(profile.attacks[1].flavour_id, flavours.FIRE,
        "red attack burns")
    harness.equal(profile.resistances[1].id, resistance.FIRE,
        "red body resists fire")
    harness.equal(profile.resistances[1].level, 1,
        "ordinary fire resistance")
    harness.equal(visible.name, "red ugly thing",
        "terminal shows the actor colour name")
    harness.equal(visible.color_id, "RED",
        "terminal uses actor colour")
    harness.equal(very_profile.colour_id, "LIGHTMAGENTA",
        "very ugly colour is bright")
    harness.equal(very_profile.attacks[1].damage, 36,
        "purple very ugly damage gets source bonus")
    harness.equal(species.colour_id, "COLOUR_UNDEF",
        "catalog was not mutated by one actor")
end

-- Source Malmutate forces a change even without adjacent energy. A nearby
-- different-coloured kin then supplies its own colour. Combat reads the
-- changed actor without losing HP or HD.
local function check_malmutation(ctx)
    local game = world(ctx)
    local actor = factory.spawn(game,
        monsters.MONS_UGLY_THING, 1, 19, 15)
    local definition = catalog.get("monsters", monsters.MONS_UGLY_THING)
    local before = ctx:get(actor, component.HEALTH)
    local initial = ctx:get(actor, component.UGLY_THING)

    harness.truthy(malmutation.apply(game, actor, definition,
        streams.MONSTER_TRAITS), "ugly thing accepts Malmutate")
    harness.truthy(ctx:get(actor, component.UGLY_THING).colour_id ~=
        initial.colour_id,
        "Malmutate forces a new colour without nearby energy")

    factory.spawn(game, monsters.MONS_UGLY_THING, 1, 20, 15, {
        colour = "green",
    })

    local ordinary_random = game.random

    function game:random(stream, bound)
        if stream == streams.MONSTER_TRAITS and bound == 9 then
            return 1
        end

        return ordinary_random(self, stream, bound)
    end

    harness.truthy(malmutation.apply(game, actor, definition,
        streams.MONSTER_TRAITS), "direct Malmutate ignores natural chance")
    harness.equal(ctx:get(actor, component.UGLY_THING).colour_id,
        "GREEN", "forced mutation copies adjacent kin colour")

    game.random = ordinary_random

    local profile = monster_profile.definition(game, actor, definition)
    local after = ctx:get(actor, component.HEALTH)

    harness.equal(profile.colour_id, "GREEN",
        "Malmutate copies the neighbouring colour")
    harness.equal(profile.attacks[1].flavour_id, flavours.POISON,
        "combat uses the new attack flavour")
    harness.equal(profile.resistances[1].id, resistance.POISON,
        "combat uses the new resistance")
    harness.equal(after.current, before.current,
        "Malmutate preserves current HP")
    harness.equal(after.max, before.max,
        "Malmutate preserves maximum HP")
    harness.truthy(not ctx:has(actor, component.WRETCHED),
        "ugly things do not gain Wretched")
end

-- An awake ugly thing can copy a neighbouring kin colour on its source
-- special-ability chance. The neighbour's actor traits stay unchanged.
local function check_nearby_mutation(ctx)
    local game = world(ctx)
    local actor = factory.spawn(game,
        monsters.MONS_UGLY_THING, 1, 27, 15)
    local kin = factory.spawn(game,
        monsters.MONS_UGLY_THING, 1, 28, 15, {
            colour = "green",
        })
    local before = ctx:get(kin, component.UGLY_THING)

    ctx:add(game:player(), component.ACTOR, {
        kind_id = monsters.MONS_HUMAN,
        speed = 10,
    })
    ctx:add(game:player(), component.HEALTH, {
        current = 100,
        max = 100,
    })
    ctx:add(game:player(), component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    ctx:set(game:player(), component.POSITION, {
        level_id = 1,
        x = 27,
        y = 17,
    })

    harness.truthy(ugly_thing.tick(game, actor),
        "adjacent kin permits a spontaneous mutation")
    harness.equal(ctx:get(actor, component.UGLY_THING).adjective,
        "green", "source colour follows neighbouring kin")
    harness.equal(ctx:get(kin, component.UGLY_THING).adjective,
        before.adjective, "neighbouring actor stays unchanged")
end

-- A natural colour mutation is the monster's special action for this turn.
-- It must yield a wait intent so the same actor cannot also move or strike.
local function check_mutation_spends_action(ctx)
    local game = world(ctx)
    local actor = factory.spawn(game,
        monsters.MONS_UGLY_THING, 1, 42, 15)

    factory.spawn(game, monsters.MONS_UGLY_THING, 1, 43, 15, {
        colour = "green",
    })

    ctx:add(game:player(), component.ACTOR, {
        kind_id = monsters.MONS_HUMAN,
        speed = 10,
    })
    ctx:add(game:player(), component.HEALTH, {
        current = 100,
        max = 100,
    })
    ctx:add(game:player(), component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    ctx:add(game:player(), component.ATTRIBUTES, {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(game:player(), component.SKILLS, {
        entries = {},
    })
    ctx:set(game:player(), component.POSITION, {
        level_id = 1,
        x = 42,
        y = 17,
    })

    decision.update(game, actor)

    harness.equal(ctx:get(actor, component.UGLY_THING).adjective,
        "green", "natural mutation occurred during decision")
    harness.equal(ctx:get(actor, component.INTENT).kind, 6,
        "natural mutation consumed the actor action")
end

-- Polymorph changes species on the same entity. Its body transition must
-- attach and retire the saved profile with the two ugly species.
local function check_polymorph(ctx)
    local game = world(ctx)
    local actor = factory.spawn(game, monsters.MONS_RAT, 1, 31, 15)

    polymorph.fixed(game, actor,
        catalog.get("monsters", monsters.MONS_UGLY_THING))

    harness.truthy(ctx:has(actor, component.UGLY_THING),
        "polymorph into ugly thing creates saved traits")

    polymorph.fixed(game, actor,
        catalog.get("monsters", monsters.MONS_RAT))

    harness.truthy(not ctx:has(actor, component.UGLY_THING),
        "polymorph away removes obsolete ugly traits")
end

-- Source Polymorph treats an existing ugly thing specially: it forces a
-- colour mutation instead of choosing another species.
local function check_ugly_polymorph(ctx)
    local game = world(ctx)
    local actor = factory.spawn(game,
        monsters.MONS_UGLY_THING, 1, 38, 15)
    local definition = catalog.get("monsters", monsters.MONS_UGLY_THING)
    local before = ctx:get(actor, component.UGLY_THING)

    harness.truthy(polymorph.shapeshift(game, actor, definition,
        streams.MONSTER_TRAITS), "Polymorph accepts ugly thing")
    harness.equal(ctx:get(actor, component.ACTOR).kind_id,
        monsters.MONS_UGLY_THING,
        "Polymorph does not replace ugly species")
    harness.truthy(ctx:get(actor, component.UGLY_THING).colour_id ~=
        before.colour_id,
        "Polymorph changes colour even without adjacent energy")
end

-- Save validation must reject a forged colour/flavour pairing instead of
-- loading an actor whose display and combat rules disagree.
local function check_saved_profile(ctx)
    local game = world(ctx)
    local actor = factory.spawn(game,
        monsters.MONS_UGLY_THING, 1, 34, 15)
    local definition = catalog.get("monsters", monsters.MONS_UGLY_THING)
    local state = ctx:get(actor, component.UGLY_THING)

    ugly_thing.validate(game, actor, definition)

    state.flavour_id = flavours.COLD
    ctx:set(actor, component.UGLY_THING, state)

    local valid = pcall(ugly_thing.validate, game, actor, definition)

    harness.truthy(not valid,
        "save rejects an attack flavour unrelated to actor colour")
end

-- Each case uses the real schema, factory, profile, and presentation policy.
function test.run(ctx)
    check_spawn(ctx)
    check_malmutation(ctx)
    check_contact_flavours(ctx)
    check_elemental_kill_credit(ctx)
    check_nearby_mutation(ctx)
    check_mutation_spends_action(ctx)
    check_polymorph(ctx)
    check_ugly_polymorph(ctx)
    check_saved_profile(ctx)
end

return test
