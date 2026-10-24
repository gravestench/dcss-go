-- Live willpower combines the current body, shield, jewellery, artefacts,
-- HD, and timed statuses before a hex spends its two saving-throw draws.
local artefact_kinds = require("constants.artefact_kinds")
local armour_egos = require("constants.armour_egos")
local catalog = require("policy.catalog")
local component = require("constants.component")
local harness = require("tests.harness")
local item_ids = require("ids.items")
local monsters = require("ids.monsters")
local skills = require("ids.skills")
local properties = require("ids.artefact_properties")
local unique_ids = require("ids.artefacts")
local fixture = require("tests.monster_ally_support_fixture")
local will = require("policy.magic.effects.zaps.will")
local willpower = require("policy.combat.monster_willpower")
local mirror = require("policy.magic.effects.summons.phantom_mirror")
local summons = require("policy.magic.effects.summons.common")

local test = {}

-- Use real catalog monsters so HD and item-use rules remain production data.
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

-- Equip real item kinds; the ECS records, not a substituted catalogue,
-- decide what the willpower owner sees.
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

-- The body flag, shield ego, Guile, and ring each contribute source
-- forty-point pips only while the item is equipped.
local function ordinary_equipment(ctx)
    local monster, definition = actor(ctx, monsters.MONS_ORC_WIZARD)

    harness.equal(willpower.level(ctx, monster, definition), 20,
        "orc wizard begins with catalog willpower")

    local body = wear(ctx, monster,
        item_ids.ARM_QUICKSILVER_DRAGON_ARMOUR, "body")

    harness.equal(willpower.level(ctx, monster, definition), 60,
        "quicksilver body flag adds one willpower pip")

    local shield = wear(ctx, monster, item_ids.ARM_BUCKLER,
        "shield", armour_egos.WILLPOWER)

    harness.equal(willpower.level(ctx, monster, definition), 100,
        "willpower shield adds a second pip")

    local ring = wear(ctx, monster, item_ids.RING_WILLPOWER,
        "jewellery")

    harness.equal(willpower.level(ctx, monster, definition), 140,
        "worn willpower ring adds one pip")

    ctx:remove(shield, component.EQUIPPED)

    harness.equal(willpower.level(ctx, monster, definition), 100,
        "removing shield immediately removes its bonus")

    ctx:remove(body, component.EQUIPPED)
    ctx:remove(ring, component.EQUIPPED)
    wear(ctx, monster, item_ids.ARM_BUCKLER,
        "shield", armour_egos.GUILE)

    harness.equal(willpower.level(ctx, monster, definition), 0,
        "Guile subtracts two pips before the zero floor")
end

-- Artefact properties count active gear, including a dual wielder's
-- second weapon, but never count an ordinary spare weapon.
local function artefacts_and_folly(ctx)
    local monster, definition = actor(ctx, monsters.MONS_ORC_WIZARD)
    local weapon = wear(ctx, monster, item_ids.WPN_DAGGER, "weapon")

    ctx:add(weapon, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.RANDOM,
        properties = {
            [properties.WILLPOWER] = 2,
        },
    })

    harness.equal(willpower.level(ctx, monster, definition), 100,
        "wielded artefact adds two willpower pips")

    local spare = wear(ctx, monster, item_ids.WPN_DAGGER,
        "alternate_weapon")

    ctx:add(spare, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.RANDOM,
        properties = {
            [properties.WILLPOWER] = 1,
        },
    })

    harness.equal(willpower.level(ctx, monster, definition), 100,
        "single wielder's spare artefact grants no willpower")

    local ogre, ogre_kind = actor(ctx, monsters.MONS_TWO_HEADED_OGRE)
    local second = wear(ctx, ogre, item_ids.WPN_DAGGER,
        "alternate_weapon")

    ctx:add(second, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.RANDOM,
        properties = {
            [properties.WILLPOWER] = 1,
        },
    })

    harness.equal(willpower.level(ctx, ogre, ogre_kind), 80,
        "dual wielder's second artefact is active")

    local folly = wear(ctx, monster, item_ids.ARM_ROBE, "body")

    ctx:add(folly, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.UNIQUE,
        unique_id = unique_ids.UNRAND_FOLLY,
        properties = {},
        flags = {},
    })

    harness.equal(willpower.level(ctx, monster, definition), 0,
        "robe of Folly overrides ordinary equipment")
end

-- Timed bonuses and debuffs apply after the base and gear; drained HD
-- scales only the base before the eighty-point Trog bonus is added.
local function statuses(ctx)
    local monster, definition = actor(ctx, monsters.MONS_ORC_WIZARD)

    ctx:add(monster, component.MONSTER_TROGS_HAND, {
        remaining_aut = 100,
    })

    harness.equal(willpower.level(ctx, monster, definition), 100,
        "Trog's Hand adds eighty willpower")

    ctx:add(monster, component.MONSTER_LOWERED_WILL, {
        remaining_aut = 100,
    })

    harness.equal(willpower.level(ctx, monster, definition), 50,
        "Lowered Will halves the total after Trog's Hand")

    ctx:remove(monster, component.MONSTER_LOWERED_WILL)
    ctx:add(monster, component.MONSTER_DRAINED, {
        degree = 1,
        remaining_aut = 100,
    })

    harness.equal(willpower.level(ctx, monster, definition), 93,
        "drain scales the base twenty to thirteen before Trog's Hand")

    local immune, immune_kind = actor(ctx, monsters.MONS_ORB_OF_DESTRUCTION)

    harness.equal(willpower.level(ctx, immune, immune_kind), 5000,
        "source invulnerable will remains an early sentinel")
end

-- A draconian job inherits intrinsic willpower from its saved colour,
-- just as the source resolves base_monster before reading class willpower.
local function draconian_base(ctx)
    local monster, definition = actor(ctx, monsters.MONS_DRACONIAN_SHIFTER)

    ctx:add(monster, component.MONSTER_DRACONIAN_BASE, {
        base_id = monsters.MONS_PURPLE_DRACONIAN,
    })

    harness.equal(willpower.level(ctx, monster, definition), 140,
        "purple-based draconian job inherits purple willpower")
end

-- A fixed two-draw saving throw makes equipment the only changed input.
local function live_save(ctx)
    local monster, definition = actor(ctx, monsters.MONS_ORC_WIZARD)
    local draws = 0

    function ctx:random(stream, bound)
        harness.equal(stream, "spell", "hex keeps its spell stream")
        harness.truthy(bound == 100 or bound == 101,
            "hex keeps its two source bounds")
        draws = draws + 1

        return 30
    end

    harness.equal(will.margin(ctx, definition, 100, monster), -8,
        "unprotected monster's check has a negative margin")
    harness.equal(draws, 2, "unprotected hex spends two draws")

    wear(ctx, monster, item_ids.RING_WILLPOWER, "jewellery")

    harness.equal(will.margin(ctx, definition, 100, monster), 32,
        "equipped ring raises the check margin by forty")
    harness.equal(draws, 4, "protected hex still spends two draws")

    harness.truthy(will.resists(ctx, definition, 100, monster),
        "ordinary hex uses the same positive margin")
    harness.equal(draws, 6, "ordinary hex also spends only two draws")

    local caster = actor(ctx, monsters.MONS_ORC_WIZARD)

    wear(ctx, caster, item_ids.ARM_BUCKLER, "shield",
        armour_egos.GUILE)

    harness.equal(will.margin(ctx, definition, 100,
        monster, nil, caster), -28,
        "caster Guile lowers target will by eighty before the roll")
    harness.equal(willpower.level(ctx, monster, definition), 60,
        "caster Guile does not alter the target's owned willpower")
    harness.equal(draws, 8, "Guile check still spends two draws")
end

-- Phantom Mirror uses the actual rolled will check to shorten a clone's
-- duration, so a newly equipped ring must change the same target's result.
local function mirror_duration(ctx)
    local game = fixture.observed_context(ctx)
    local player = game:player()
    local target = actor(game, monsters.MONS_ORC_WIZARD)
    local durations = {}

    game:place_actor(target, 1, 8, 7)
    game:add(player, component.SKILLS, {
        entries = {
            {
                id = skills.SK_EVOCATIONS,
                level = 12,
                points = 0,
            },
        },
    })

    function game:random(_, bound)
        return math.min(40, bound - 1)
    end

    local original_spawn = summons.spawn

    -- Only the spawn boundary is observed; targeting, the live owner,
    -- check_willpower rolls, and duration arithmetic remain production.
    summons.spawn = function(_, _, _, _, duration)
        durations[#durations + 1] = duration

        return nil
    end

    local okay, err = pcall(function()
        mirror.resolve(game, player, { dx = 1, dy = 0 })
        wear(game, target, item_ids.RING_WILLPOWER, "jewellery")
        mirror.resolve(game, player, { dx = 1, dy = 0 })
    end)

    summons.spawn = original_spawn

    if not okay then
        error(err)
    end

    harness.equal(durations[1], 3,
        "ordinary will gives the source three-turn mirror duration")
    harness.equal(durations[2], 2,
        "worn ring shortens the mirror's live will-check duration")
end

-- Run the whole willpower category against the real ECS and Lua catalog.
function test.run(ctx)
    local game = fixture.observed_context(ctx)

    ordinary_equipment(game)
    artefacts_and_folly(game)
    statuses(game)
    draconian_base(game)
    live_save(game)
    mirror_duration(ctx)
end

return test
