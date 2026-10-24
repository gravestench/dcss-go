-- Monster resistance reads live equipment, so a vault or mod can change
-- defenses simply by changing the monster's worn ECS items.
local armour_egos = require("constants.armour_egos")
local artefact_kinds = require("constants.artefact_kinds")
local catalog = require("policy.catalog")
local component = require("constants.component")
local constructs = require("constants.monster_construct_components")
local item_ids = require("ids.items")
local monsters = require("ids.monsters")
local properties = require("ids.artefact_properties")
local unique_ids = require("ids.artefacts")
local resistance_ids = require("constants.resistance_ids")
local resistance = require("policy.combat.monster_resistance")
local projection = require("policy.combat.monster_summons.resistance")
local damage = require("policy.magic.damage")
local poison = require("policy.combat.monster_poison")
local drain = require("policy.combat.monster_drain")
local cloud_resistance = require("policy.clouds.effects.resistance")
local miasma = require("policy.clouds.effects.miasma")
local torment = require("policy.combat.torment")
local harness = require("tests.harness")
local fixture = require("tests.monster_ally_support_fixture")

local test = {}

-- Use source catalog monsters, then change only their actual equipment.
local function actor(ctx, kind)
    local entity = ctx:create()

    ctx:add(entity, component.ACTOR, {
        kind_id = kind,
        speed = 10,
    })
    ctx:add(entity, component.HEALTH, {
        current = 20,
        max = 20,
    })

    return entity, catalog.get("monsters", kind)
end

-- Item definitions remain production catalog entries; only the item and
-- equipment components are fixture state.
local function wear(ctx, holder, kind, slot, ego)
    local entity = ctx:create()

    ctx:add(entity, component.ITEM, {
        kind_id = kind,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = ego or "",
    })
    ctx:add(entity, component.CARRIED_BY, { holder = holder })
    ctx:add(entity, component.EQUIPPED, { slot = slot })

    return entity
end

-- Armour flags and egos add to the source monster's innate level only
-- while it can use the gear and the relevant item remains equipped.
local function armour_and_eligibility(ctx)
    local orc, orc_kind = actor(ctx, monsters.MONS_ORC_WIZARD)
    local shield = wear(ctx, orc, item_ids.ARM_BUCKLER,
        "shield", armour_egos.FIRE_RESISTANCE)

    harness.equal(resistance.level(ctx, orc, orc_kind,
        resistance_ids.FIRE), 1,
        "worn fire shield grants monster rF")
    harness.equal(resistance.level(ctx, orc, orc_kind,
        resistance_ids.STEAM), 1,
        "monster steam resistance derives from live fire resistance")

    ctx:add(orc, component.FIRE_VULNERABILITY, {
        remaining_aut = 100,
    })

    harness.equal(resistance.level(ctx, orc, orc_kind,
        resistance_ids.FIRE), 0,
        "temporary fire vulnerability applies after equipped shield")

    ctx:remove(orc, component.FIRE_VULNERABILITY)

    local body = wear(ctx, orc, item_ids.ARM_FIRE_DRAGON_ARMOUR, "body")

    harness.equal(resistance.level(ctx, orc, orc_kind,
        resistance_ids.FIRE), 3,
        "dragon armour flag and shield ego stack to rF three")
    harness.equal(resistance.level(ctx, orc, orc_kind,
        resistance_ids.COLD), -1,
        "fire dragon armour carries its source cold vulnerability")

    ctx:remove(shield, component.EQUIPPED)

    harness.equal(resistance.level(ctx, orc, orc_kind,
        resistance_ids.FIRE), 2,
        "removing a shield removes its monster resistance")

    local rat, rat_kind = actor(ctx, monsters.MONS_RAT)

    wear(ctx, rat, item_ids.ARM_FIRE_DRAGON_ARMOUR, "body")

    harness.equal(resistance.level(ctx, rat, rat_kind,
        resistance_ids.FIRE), 0,
        "monster unable to use items receives no worn resistance")

    ctx:remove(body, component.EQUIPPED)
end

-- Jewellery and a wielded staff use the same equipped snapshot as armour;
-- poison from gear stops at one pip even with multiple sources.
local function other_gear(ctx)
    local orc, definition = actor(ctx, monsters.MONS_ORC_WIZARD)

    wear(ctx, orc, item_ids.RING_ICE, "jewellery")
    wear(ctx, orc, item_ids.STAFF_FIRE, "weapon")

    harness.equal(resistance.level(ctx, orc, definition,
        resistance_ids.FIRE), 0,
        "fire staff and ice ring cancel for monster rF")
    harness.equal(resistance.level(ctx, orc, definition,
        resistance_ids.COLD), 1,
        "ice ring grants monster rC")

    local poisoned, poisoned_kind = actor(ctx, monsters.MONS_ORC_WIZARD)

    wear(ctx, poisoned, item_ids.ARM_SWAMP_DRAGON_ARMOUR, "body")
    wear(ctx, poisoned, item_ids.ARM_BUCKLER, "shield",
        armour_egos.POISON_RESISTANCE)

    harness.equal(resistance.level(ctx, poisoned, poisoned_kind,
        resistance_ids.POISON), 1,
        "poison equipment is capped at one pip")

    local olgreb, olgreb_kind = actor(ctx,
        monsters.MONS_ORC_WIZARD)
    local staff = wear(ctx, olgreb, item_ids.WPN_STAFF,
        "weapon")

    ctx:add(staff, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.UNIQUE,
        unique_id = unique_ids.UNRAND_OLGREB,
        properties = {},
        flags = {},
    })

    harness.equal(resistance.level(ctx, olgreb, olgreb_kind,
        resistance_ids.POISON), 3,
        "wielded staff of Olgreb grants full poison immunity")

    local rat, rat_kind = actor(ctx, monsters.MONS_RAT)
    local impossible_staff = wear(ctx, rat, item_ids.WPN_STAFF,
        "weapon")

    ctx:add(impossible_staff, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.UNIQUE,
        unique_id = unique_ids.UNRAND_OLGREB,
        properties = {},
        flags = {},
    })

    harness.equal(resistance.level(ctx, rat, rat_kind,
        resistance_ids.POISON), 3,
        "source Olgreb check precedes ordinary item-use gating")

    local charged, charged_kind = actor(ctx,
        monsters.MONS_ORC_WIZARD)

    wear(ctx, charged, item_ids.ARM_STORM_DRAGON_ARMOUR, "body")

    harness.equal(resistance.level(ctx, charged, charged_kind,
        resistance_ids.ELECTRICITY), 1,
        "storm dragon armour grants monster electric resistance")

    local steamy, steamy_kind = actor(ctx,
        monsters.MONS_ORC_WIZARD)

    wear(ctx, steamy, item_ids.ARM_STEAM_DRAGON_ARMOUR, "body")

    harness.equal(resistance.level(ctx, steamy, steamy_kind,
        resistance_ids.STEAM), 3,
        "steam dragon scales grant source monster rSteam three")

    local embrace, embrace_kind = actor(ctx,
        monsters.MONS_ORC_WIZARD)
    local armour = wear(ctx, embrace,
        item_ids.ARM_LEATHER_ARMOUR, "body")

    ctx:add(armour, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.UNIQUE,
        unique_id = unique_ids.UNRAND_EMBRACE,
        properties = {},
        flags = {},
    })

    harness.equal(resistance.level(ctx, embrace, embrace_kind,
        resistance_ids.MIASMA), 1,
        "Cigotuvi's Embrace grants miasma immunity")
    harness.truthy(miasma.immune(ctx, embrace),
        "miasma cloud checks equipped Embrace")

    local acid, acid_kind = actor(ctx, monsters.MONS_ORC_WIZARD)

    wear(ctx, acid, item_ids.RING_RESIST_CORROSION,
        "jewellery")
    wear(ctx, acid, item_ids.ARM_ACID_DRAGON_ARMOUR, "body")

    harness.equal(resistance.level(ctx, acid, acid_kind,
        resistance_ids.ACID), 1,
        "ring and acid dragon scales grant boolean monster rCorr")

    ctx:add(acid, constructs.RESISTANCE, {
        remaining_aut = 100,
    })

    harness.equal(damage.monster_resistance(ctx, acid,
        resistance_ids.ACID), 2,
        "temporary resistance adds after the acid gear maximum")

    local ogre, ogre_kind = actor(ctx,
        monsters.MONS_TWO_HEADED_OGRE)
    local second = wear(ctx, ogre, item_ids.WPN_DAGGER,
        "alternate_weapon")

    ctx:add(second, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.RANDOM,
        properties = {
            [properties.FIRE] = 1,
        },
    })

    harness.equal(resistance.level(ctx, ogre, ogre_kind,
        resistance_ids.FIRE), 1,
        "dual wielder receives alternate weapon artefact resistance")

    local one_weapon, one_weapon_kind = actor(ctx,
        monsters.MONS_ORC_WIZARD)
    local spare = wear(ctx, one_weapon, item_ids.WPN_DAGGER,
        "alternate_weapon")

    ctx:add(spare, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.RANDOM,
        properties = {
            [properties.FIRE] = 1,
        },
    })

    harness.equal(resistance.level(ctx, one_weapon,
        one_weapon_kind, resistance_ids.FIRE), 0,
        "spare weapon grants no resistance to single wielder")
end

-- Projecting a timed enchantment must preserve the intrinsic three-pip
-- value until vulnerable gear and the final source cap are applied.
local function enchantment_order(ctx)
    local monster, kind = actor(ctx, monsters.MONS_ORC_WIZARD)
    local definition = {}

    for key, value in pairs(kind) do
        definition[key] = value
    end

    definition.resistances = {
        {
            id = resistance_ids.FIRE,
            level = 3,
        },
    }

    wear(ctx, monster, item_ids.ARM_ICE_DRAGON_ARMOUR, "body")
    ctx:add(monster, constructs.RESISTANCE, {
        remaining_aut = 100,
    })

    local projected = projection.project(ctx, monster, definition)

    harness.equal(resistance.level(ctx, monster, projected,
        resistance_ids.FIRE), 3,
        "enchantment restores rF after vulnerable gear before cap")

    local generated = {}

    for key, value in pairs(kind) do
        generated[key] = value
    end

    generated.resistances = {
        {
            id = resistance_ids.FIRE,
            level = 1,
        },
        {
            id = resistance_ids.FIRE,
            level = 2,
        },
    }

    local overlay_actor = actor(ctx, monsters.MONS_ORC_WIZARD)

    harness.equal(resistance.level(ctx, overlay_actor, generated,
        resistance_ids.FIRE), 2,
        "generated monster's final intrinsic override wins")
end

-- Artefact properties are scanned once across worn items. Negative-energy
-- immunity from undead holiness still wins over any equipped modifier.
local function artefact_and_holiness(ctx)
    local orc, definition = actor(ctx, monsters.MONS_ORC_WIZARD)
    local shield = wear(ctx, orc, item_ids.ARM_BUCKLER,
        "shield", armour_egos.RESISTANCE)

    ctx:add(shield, component.ITEM_ARTEFACT, {
        kind = "random",
        properties = {
            [properties.FIRE] = 1,
        },
    })

    harness.equal(resistance.level(ctx, orc, definition,
        resistance_ids.FIRE), 2,
        "artefact property and ego each add one fire pip")

    local undead, undead_kind = actor(ctx, monsters.MONS_WIGHT)

    wear(ctx, undead, item_ids.ARM_BUCKLER,
        "shield", armour_egos.POSITIVE_ENERGY)

    harness.equal(resistance.level(ctx, undead, undead_kind,
        resistance_ids.NEGATIVE_ENERGY), 3,
        "undead remains immune to negative energy with gear")
end

-- The ordinary combat entry points must read the same live gear result as
-- the owner; otherwise spells and poison would ignore equipped shields.
local function combat_consumers(ctx)
    local orc, definition = actor(ctx, monsters.MONS_ORC_WIZARD)
    local shield = wear(ctx, orc, item_ids.ARM_BUCKLER,
        "shield", armour_egos.FIRE_RESISTANCE)

    harness.equal(damage.monster_resistance(ctx, orc,
        resistance_ids.FIRE), 1,
        "monster resistance query sees worn fire shield")
    harness.equal(damage.monster_elemental(ctx, orc, 18,
        resistance_ids.FIRE), 9,
        "fire damage is reduced by worn shield")

    ctx:remove(shield, component.EQUIPPED)

    harness.equal(damage.monster_elemental(ctx, orc, 18,
        resistance_ids.FIRE), 18,
        "fire damage changes immediately after shield removal")

    local cold_shield = wear(ctx, orc, item_ids.ARM_BUCKLER,
        "shield", armour_egos.COLD_RESISTANCE)

    harness.equal(damage.monster_elemental(ctx, orc, 18,
        resistance_ids.COLD), 9,
        "cold spell damage reads a worn resistance shield")

    ctx:remove(cold_shield, component.EQUIPPED)

    harness.equal(damage.monster_elemental(ctx, orc, 18,
        resistance_ids.COLD), 18,
        "cold spell damage changes when the shield is removed")

    wear(ctx, orc, item_ids.ARM_BUCKLER, "shield",
        armour_egos.POISON_RESISTANCE)

    harness.equal(poison.effective_resistance(ctx, orc, definition), 1,
        "poison application sees worn shield")

    local protected, protected_kind = actor(ctx,
        monsters.MONS_ORC_WIZARD)

    wear(ctx, protected, item_ids.ARM_BUCKLER,
        "shield", armour_egos.POSITIVE_ENERGY)

    harness.equal(drain.resistance(ctx, protected, protected_kind), 1,
        "negative energy drain shares worn shield resistance")

    harness.equal(torment.monster_loss(ctx, protected,
        protected_kind, 20), 8,
        "Torment's nonlethal loss includes worn negative resistance")

    harness.equal(cloud_resistance.monster(ctx, orc,
        resistance_ids.POISON), 1,
        "cloud immunity reads the same worn poison resistance")
end

-- Run the complete gear category against production item and monster data.
function test.run(ctx)
    local game = fixture.observed_context(ctx)

    armour_and_eligibility(game)
    other_gear(game)
    artefact_and_holiness(game)
    combat_consumers(game)
    enchantment_order(game)
end

return test
