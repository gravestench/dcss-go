-- Elemental monster contacts use catalog actors and production status schemas.
-- This isolates flavour decisions from hit rolls while retaining real ECS data.
local attacks = require("policy.combat.monster_attack_flavours")
local actions = require("policy.combat.melee_actions")
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local flavours = require("constants.attack_flavours")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local species = require("ids.species")
local spells = require("ids.spells")

local test = {}

-- A live melee owner supplies these values after its physical contact.
-- Base damage is kept apart from damage already dealt through armour.
local function hit(attacker, defender, definition, base, dealt)
    return {
        kind = "hit",
        attacker = attacker,
        attacker_name = "contact monster",
        defender = defender,
        defender_definition = definition,
        hit_dice = 8,
        attack_base_damage = base,
        defender_ac = 0,
        physical_damage = dealt,
        damage_done = dealt,
    }
end

-- Source Holy reads the attack's base damage and only susceptible bodies
-- take its secondary packet. A profane servitor is specially resistant.
local function holy_contact(ctx, game, attacker, player)
    local human = hit(attacker, player, nil, 20, 4)
    local player_health = ctx:get(player, component.HEALTH).current

    harness.falsy(attacks.apply(game, flavours.HOLY, human),
        "natural player takes no holy packet")
    harness.equal(ctx:get(player, component.HEALTH).current,
        player_health, "natural player health remains unchanged")

    ctx:set(player, component.PLAYER, {
        species_id = species.SP_MUMMY,
    })
    harness.truthy(attacks.apply(game, flavours.HOLY, human),
        "undead player takes holy packet")
    harness.equal(ctx:get(player, component.HEALTH).current,
        player_health - 15, "holy packet uses attack base damage")

    -- HP loss can be absorbed after armour (for example by Spirit Shield).
    -- The source still runs Holy from its positive physical packet.
    human.damage_done = 0
    harness.truthy(attacks.apply(game, flavours.HOLY, human),
        "post-armour contact triggers Holy despite absorbed HP loss")
    human.damage_done = 4

    local wraith = fixture.actor(ctx, monsters.MONS_WRAITH,
        11, 11, 100)
    local wraith_hit = hit(attacker, wraith,
        catalog.get("monsters", monsters.MONS_WRAITH), 20, 3)

    harness.truthy(attacks.apply(game, flavours.HOLY, wraith_hit),
        "undead monster takes holy packet")
    harness.equal(ctx:get(wraith, component.HEALTH).current, 85,
        "monster holy packet uses same source amount")

    local profane = fixture.actor(ctx,
        monsters.MONS_PROFANE_SERVITOR, 12, 11, 100)

    harness.falsy(attacks.apply(game, flavours.HOLY,
        hit(attacker, profane, catalog.get("monsters",
            monsters.MONS_PROFANE_SERVITOR), 20, 3)),
        "profane servitor resists holy despite undead body")
end

-- A fire vortex has no physical strike. Its landed contact still draws a
-- fire packet, then spends its own life; a nonvortex elemental survives.
local function pure_fire_contact(ctx, game, player)
    local vortex = fixture.actor(ctx, monsters.MONS_FIRE_VORTEX,
        20, 10, 100)
    local impact = hit(vortex, player, nil, 0, 0)
    local before = ctx:get(player, component.HEALTH).current

    harness.truthy(attacks.apply(game, flavours.PURE_FIRE, impact),
        "zero-physical-damage contact still burns")
    harness.truthy(ctx:get(player, component.HEALTH).current < before,
        "fire packet reaches player health")
    harness.equal(ctx:get(vortex, component.HEALTH).current, 0,
        "vortex expires after a landed contact")

    local missed = fixture.actor(ctx, monsters.MONS_FIRE_VORTEX,
        21, 10, 100)
    local miss = hit(missed, player, nil, 0, 0)

    miss.kind = "miss"
    harness.falsy(attacks.apply(game, flavours.PURE_FIRE, miss),
        "missed vortex contact has no fire packet")
    harness.equal(ctx:get(missed, component.HEALTH).current, 100,
        "missed vortex remains alive")

    local elemental = fixture.actor(ctx, monsters.MONS_FIRE_ELEMENTAL,
        22, 10, 100)
    local orc = fixture.actor(ctx, monsters.MONS_ORC, 23, 10, 100)
    local orc_hit = hit(elemental, orc,
        catalog.get("monsters", monsters.MONS_ORC), 0, 0)

    harness.truthy(attacks.apply(game, flavours.PURE_FIRE, orc_hit),
        "fire elemental burns monster at zero physical damage")
    harness.truthy(ctx:get(orc, component.HEALTH).current < 100,
        "monster receives the separate fire packet")
    harness.equal(ctx:get(elemental, component.HEALTH).current, 100,
        "fire elemental survives its contact")

    local armoured = fixture.actor(ctx, monsters.MONS_ORC,
        24, 10, 100)
    local armoured_hit = hit(elemental, armoured,
        catalog.get("monsters", monsters.MONS_ORC), 0, 0)

    armoured_hit.defender_ac = 6
    ctx:add(armoured, component.FIRE_VULNERABILITY, {
        remaining_aut = 30,
    })

    -- HD eight rolls twelve raw fire; AC six rolls four, saving two.
    -- The live vulnerability then multiplies the ten-point packet.
    function game:random(_, bound)
        if bound == 7 then
            return 4
        end

        return 0
    end

    attacks.apply(game, flavours.PURE_FIRE, armoured_hit)
    harness.equal(ctx:get(armoured, component.HEALTH).current, 85,
        "half armour precedes saved fire vulnerability")

    function game:random()
        return 0
    end
end

-- Sear reuses the same saved weakness read by fire resistance. The player
-- clock caps while monster enchantments retain their own additive timer.
local function sear_contact(ctx, game, attacker, player)
    local player_hit = hit(attacker, player, nil, 30, 5)

    harness.truthy(attacks.apply(game, flavours.SEAR, player_hit),
        "damaging Sear contact weakens player fire resistance")
    harness.equal(ctx:get(player,
        component.FIRE_VULNERABILITY).remaining_aut, 30,
        "first Sear contact starts three turns")

    ctx:set(player, component.FIRE_VULNERABILITY, {
        remaining_aut = 490,
    })
    attacks.apply(game, flavours.SEAR, player_hit)
    harness.equal(ctx:get(player,
        component.FIRE_VULNERABILITY).remaining_aut, 500,
        "player Sear duration caps at fifty turns")

    local orc = fixture.actor(ctx, monsters.MONS_ORC,
        31, 10, 100)
    local monster_hit = hit(attacker, orc,
        catalog.get("monsters", monsters.MONS_ORC), 30, 5)

    attacks.apply(game, flavours.SEAR, monster_hit)
    harness.equal(ctx:get(orc,
        component.FIRE_VULNERABILITY).remaining_aut, 30,
        "monster Sear status uses existing enchantment owner")

    monster_hit.damage_done = 0
    monster_hit.physical_damage = 0
    harness.falsy(attacks.apply(game, flavours.SEAR, monster_hit),
        "zero physical damage does not trigger Sear")
    harness.equal(ctx:get(orc,
        component.FIRE_VULNERABILITY).remaining_aut, 30,
        "dry hit does not extend vulnerability")

    monster_hit.physical_damage = 5
    harness.truthy(attacks.apply(game, flavours.SEAR, monster_hit),
        "post-armour Sear can proc despite absorbed HP loss")
end

-- A summoned vortex must use the ordinary monster attack envelope. A missed
-- roll leaves it intact; the next landed Pure Fire contact spends it.
local function summoned_vortex_contact(ctx, game, player)
    local vortex = fixture.actor(ctx, monsters.MONS_FIRE_VORTEX,
        40, 10, 100)
    local rat = fixture.actor(ctx, monsters.MONS_RAT,
        41, 10, 100)

    ctx:add(vortex, component.SUMMON, {
        owner = player,
        source_id = spells.SPELL_FIRE_STORM,
        expires_aut = 90,
        heads = 0,
    })

    function game:random()
        return 0
    end

    actions.monster_target(game, vortex, rat)
    harness.equal(ctx:get(vortex, component.HEALTH).current, 100,
        "missed summoned vortex stays alive")
    harness.equal(ctx:get(rat, component.HEALTH).current, 100,
        "missed summoned vortex leaves target unharmed")

    function game:random(_, bound)
        return bound - 1
    end

    actions.monster_target(game, vortex, rat)
    harness.equal(ctx:get(vortex, component.HEALTH).current, 0,
        "landed summoned vortex uses ordinary Pure Fire rule")
    harness.truthy(ctx:get(rat, component.HEALTH).current < 100,
        "landed summoned vortex burns its target")
end

-- Injury Mirror can kill an attacker during the physical packet. Source
-- melee stops before a later Holy packet when that happens.
local function reflected_holy_contact(ctx, game)
    local apis = fixture.actor(ctx, monsters.MONS_APIS,
        50, 10, 1)
    local wraith = fixture.actor(ctx, monsters.MONS_WRAITH,
        51, 10, 100)
    local physical_damage = 0

    ctx:add(wraith, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })
    ctx:add(wraith, component.MONSTER_INJURY_MIRROR, {
        remaining_aut = 100,
        recast_at_aut = 200,
    })

    function game:random(_, bound)
        return bound - 1
    end

    function game:emit(_, message)
        local dealt = message:match(" for (%d+) damage")

        if dealt then
            physical_damage = tonumber(dealt)
        end
    end

    actions.monster_target(game, apis, wraith)

    harness.equal(ctx:get(apis, component.HEALTH).current, 0,
        "physical strike reflects enough damage to kill Apis")
    harness.truthy(physical_damage > 1,
        "the reflected physical strike dealt positive damage")
    harness.equal(ctx:get(wraith, component.HEALTH).current,
        100 - physical_damage,
        "dead Apis cannot add a Holy packet after reflection")
end

-- The fixture's zero draw makes every source chance and damage roll explicit.
function test.run(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_APIS,
        10, 10, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        11, 10, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local game = fixture.context(ctx, player)

    function game:random()
        return 0
    end

    holy_contact(ctx, game, attacker, player)
    ctx:set(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    pure_fire_contact(ctx, game, player)
    sear_contact(ctx, game, attacker, player)
    summoned_vortex_contact(ctx, game, player)
    reflected_holy_contact(ctx, game)
end

return test
