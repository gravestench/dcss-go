local capabilities = require("constants.jewellery_capabilities")
local fixture = require("tests.fixtures.jewellery")
local harness = require("tests.harness")
local ids = require("ids.items")
local species = require("ids.species")
local effects = require("policy.inventory.jewellery_effects")
local formulas = require("policy.character.formulas")
local catalog = require("policy.catalog")
local jewellery_system = require("systems.item_jewellery")
local intent = require("constants.intent")
local attributes = require("policy.character.attributes")
local player_slay = require("policy.combat.player_slay")
local player_resistance = require("policy.combat.player_resistance")
local damage = require("policy.magic.damage")
local resistance_ids = require("constants.resistance_ids")
local senses = require("policy.character.senses")
local flight = require("policy.combat.flight")
local fighter = require("policy.combat.fighter")

local test = {}

local function check_item_plus(ctx)
    local battle, player = fixture.player(ctx)
    local first = fixture.carry(ctx, player, ids.RING_PROTECTION, 4)
    local second = fixture.carry(ctx, player, ids.RING_PROTECTION, -2)

    ctx:add(first, "core.equipped", { slot = "ring_left" })
    ctx:add(second, "core.equipped", { slot = "ring_right" })

    harness.equal(effects.sum(battle, player, capabilities.AC), 2,
        "signed ring pluses stack across active slots")
    ctx:remove(first, "core.equipped")
    harness.equal(effects.sum(battle, player, capabilities.AC), -2,
        "taking off a ring immediately removes its bonus")
end

local function check_octopode(ctx)
    local battle, player = fixture.player(ctx, species.SP_OCTOPODE)

    for slot = 1, 8 do
        local ring = fixture.carry(ctx, player, ids.RING_MAGICAL_POWER)

        ctx:add(ring, "core.equipped", { slot = "ring_" .. slot })
    end

    harness.equal(effects.sum(battle, player, capabilities.MAX_MP), 72,
        "all eight Octopode rings contribute once")
end

local function check_magical_power(ctx)
    local battle, player = fixture.player(ctx)
    local ring = fixture.carry(ctx, player, ids.RING_MAGICAL_POWER)
    local human = catalog.get("species", species.SP_HUMAN)

    ctx:add(player, "core.progression", { level = 1 })

    local baseline = formulas.max_mp(battle, player, 1, human, {})

    ctx:add(player, "core.magic", {
        current = baseline,
        max = baseline,
    })
    ctx:add(player, "core.intent", {
        kind = intent.JEWELLERY_ON,
        item_id = ring,
        target_id = "ring_left",
    })
    jewellery_system.update(battle, player)

    harness.equal(ctx:get(player, "core.magic").max, baseline + 9,
        "equipping magical power immediately updates maximum MP")

    ctx:set(player, "core.intent", {
        kind = intent.JEWELLERY_OFF,
        item_id = ring,
    })
    jewellery_system.update(battle, player)

    harness.equal(ctx:get(player, "core.magic").max, baseline,
        "removing magical power immediately restores maximum MP")
end

local function check_character_effects(ctx)
    local battle, player = fixture.player(ctx)
    local strength = fixture.carry(ctx, player, ids.RING_STRENGTH, 3)
    local evasion = fixture.carry(ctx, player, ids.RING_EVASION, -2)

    ctx:add(strength, "core.equipped", { slot = "ring_left" })
    ctx:add(evasion, "core.equipped", { slot = "ring_right" })

    harness.equal(attributes.current(battle, player).strength, 13,
        "strength ring changes live attributes")

    local defense = fighter.defense(battle)

    ctx:remove(evasion, "core.equipped")
    harness.equal(defense.ev, fighter.defense(battle).ev - 2,
        "negative evasion plus lowers live defense")

    ctx:remove(strength, "core.equipped")

    local slaying = fixture.carry(ctx, player, ids.RING_SLAYING, 5)

    ctx:add(slaying, "core.equipped", { slot = "ring_left" })
    harness.equal(player_slay.total(battle, player), 5,
        "slaying ring feeds the common attack bonus")

    ctx:remove(slaying, "core.equipped")

    local intelligence = fixture.carry(ctx, player, ids.RING_INTELLIGENCE, 2)
    local dexterity = fixture.carry(ctx, player, ids.RING_DEXTERITY, -1)

    ctx:add(intelligence, "core.equipped", { slot = "ring_left" })
    ctx:add(dexterity, "core.equipped", { slot = "ring_right" })

    local current = attributes.current(battle, player)

    harness.equal(current.intelligence, 12,
        "intelligence ring changes the live attribute")
    harness.equal(current.dexterity, 9,
        "negative dexterity plus changes the live attribute")

    ctx:remove(intelligence, "core.equipped")
    ctx:remove(dexterity, "core.equipped")

    local protection = fixture.carry(ctx, player, ids.RING_PROTECTION, 4)
    local original = fighter.defense(battle).ac

    ctx:add(protection, "core.equipped", { slot = "ring_left" })
    harness.equal(fighter.defense(battle).ac, original + 4,
        "protection ring changes live armour class")
end

local function check_resistances(ctx)
    local battle, player = fixture.player(ctx)
    local fire = fixture.carry(ctx, player, ids.RING_FIRE)
    local cold = fixture.carry(ctx, player, ids.RING_ICE)

    ctx:add(fire, "core.equipped", { slot = "ring_left" })

    harness.equal(damage.player_resistance(battle, player,
        resistance_ids.FIRE), 1, "fire ring grants rF")
    harness.equal(damage.player_resistance(battle, player,
        resistance_ids.COLD), -1, "fire ring imposes cold vulnerability")

    ctx:add(cold, "core.equipped", { slot = "ring_right" })

    harness.equal(damage.player_resistance(battle, player,
        resistance_ids.FIRE), 0, "fire and ice rings cancel rF")
    harness.equal(damage.player_resistance(battle, player,
        resistance_ids.COLD), 0, "fire and ice rings cancel rC")

    ctx:remove(cold, "core.equipped")
    ctx:remove(fire, "core.equipped")

    local corrosion = fixture.carry(ctx, player,
        ids.RING_RESIST_CORROSION)
    local life = fixture.carry(ctx, player,
        ids.RING_LIFE_PROTECTION)

    ctx:add(corrosion, "core.equipped", { slot = "ring_left" })
    ctx:add(life, "core.equipped", { slot = "ring_right" })

    harness.equal(damage.player_resistance(battle, player,
        resistance_ids.ACID), 1, "corrosion ring feeds acid resistance")
    harness.equal(damage.player_resistance(battle, player,
        resistance_ids.NEGATIVE_ENERGY), 1,
        "life protection ring feeds negative-energy resistance")

    ctx:remove(corrosion, "core.equipped")
    ctx:remove(life, "core.equipped")

    local poison = fixture.carry(ctx, player, ids.RING_POISON_RESISTANCE)
    local willpower = fixture.carry(ctx, player, ids.RING_WILLPOWER)

    ctx:add(poison, "core.equipped", { slot = "ring_left" })
    harness.equal(player_resistance.poison(battle, player), 1,
        "poison ring feeds the live resistance policy")

    ctx:add(player, "core.progression", { level = 1 })
    ctx:add(willpower, "core.equipped", { slot = "ring_right" })

    local source = catalog.get("species", species.SP_HUMAN)

    harness.equal(player_resistance.willpower(battle, player),
        source.mr + 40, "willpower ring contributes one source pip")
end

local function check_senses_and_flight(ctx)
    local battle, player = fixture.player(ctx)
    local sight = fixture.carry(ctx, player, ids.RING_SEE_INVISIBLE)
    local flying = fixture.carry(ctx, player, ids.RING_FLIGHT)

    ctx:add(sight, "core.equipped", { slot = "ring_left" })
    ctx:add(flying, "core.equipped", { slot = "ring_right" })

    harness.truthy(senses.see_invisible(battle, player),
        "see-invisible ring feeds perception")
    harness.truthy(flight.permanent(battle, player),
        "flight ring feeds movement")
end

function test.run(ctx)
    check_item_plus(ctx)
    check_octopode(ctx)
    check_magical_power(ctx)
    check_character_effects(ctx)
    check_resistances(ctx)
    check_senses_and_flight(ctx)
end

return test
