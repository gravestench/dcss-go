-- Xom alters a hostile's real carried item, so combat and save paths see
-- the brand later without a temporary Xom-only status on the monster.
local component = require("constants.component")
local artefact_kinds = require("constants.artefact_kinds")
local combat_brands = require("policy.combat.brands")
local effect = require("policy.religion.xom.effects.monsters.chaos_upgrade")
local events = require("policy.religion.xom.events")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local ids = require("ids.xom_events")
local items = require("ids.items")
local inventory = require("policy.inventory.items")
local missile_egos = require("constants.missile_egos")
local monsters = require("ids.monsters")
local projectiles = require("policy.combat.monster_projectiles")
local slots = require("constants.monster_equipment_slots")
local streams = require("constants.rng_streams")
local weapon_brands = require("constants.weapon_brands")

local test = {}

-- The source checks weapon, alternate weapon, then ammunition. A branded
-- weapon is left alone, while the first unbranded alternative is upgraded.
local function equip(ctx, monster, kind_id, slot, ego)
    local entity = ctx:create()

    ctx:add(entity, component.ITEM, {
        kind_id = kind_id,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = ego or "",
    })
    ctx:add(entity, component.CARRIED_BY, { holder = monster })
    ctx:add(entity, component.EQUIPPED, { slot = slot })

    return entity
end

-- One deterministic draw chooses the only monster, then the minimum
-- source enchantment increase. The same item entity survives the event.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)
    local monster = fixture.actor(ctx, monsters.MONS_GNOLL, 9, 7, 12)
    local branded = equip(ctx, monster, items.WPN_CLUB,
        slots.WEAPON, weapon_brands.VENOM)
    local plain = equip(ctx, monster, items.WPN_CLUB,
        slots.ALTERNATE_WEAPON)
    local gifted_monster = fixture.actor(ctx, monsters.MONS_GNOLL,
        10, 7, 12)
    local gift = equip(ctx, gifted_monster, items.WPN_CLUB,
        slots.WEAPON)
    local artefact_monster = fixture.actor(ctx, monsters.MONS_GNOLL,
        11, 7, 12)
    local unique = equip(ctx, artefact_monster, items.WPN_CLUB,
        slots.WEAPON)

    ctx:add(gift, component.ITEM_PROVENANCE, {
        god_id = gods.OKAWARU,
    })
    ctx:add(unique, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.UNIQUE,
        unique_id = "test_unique",
    })

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    function owner:random(stream, bound)
        if stream == streams.RELIGION then
            return 0
        end

        return ctx:random(stream, bound)
    end

    harness.equal(#effect.candidates(owner, player), 1)

    harness.truthy(events.apply(owner, player,
        ids.BAD_CHAOS_UPGRADE, 20, {
            stream = streams.RELIGION,
        }))
    harness.equal(ctx:get(branded, component.ITEM).ego,
        weapon_brands.VENOM)
    harness.equal(ctx:get(plain, component.ITEM).ego,
        weapon_brands.CHAOS)
    harness.equal(ctx:get(plain, component.ITEM).plus, 0)
    combat_brands.check(weapon_brands.CHAOS)
    harness.equal(ctx:get(gift, component.ITEM).ego, "")
    harness.equal(ctx:get(unique, component.ITEM).ego, "")

    -- Random artefacts can change brand while keeping their generated
    -- identity and ordinary item component separate.
    local randart_monster = fixture.actor(ctx, monsters.MONS_GNOLL,
        8, 8, 12)
    local randart = equip(ctx, randart_monster, items.WPN_CLUB,
        slots.WEAPON)

    ctx:add(randart, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.RANDOM,
        brand = weapon_brands.NORMAL,
    })

    harness.equal(#effect.candidates(owner, player), 1)
    harness.truthy(events.apply(owner, player,
        ids.BAD_CHAOS_UPGRADE, 20, {
            stream = streams.RELIGION,
        }))
    harness.equal(ctx:get(randart,
        component.ITEM_ARTEFACT).brand, weapon_brands.CHAOS)
    harness.equal(ctx:get(randart, component.ITEM).ego, "")

    -- A new hostile with only throwing stones receives a saved ammo ego.
    -- The ordinary monster projectile policy must accept that same ego.
    local thrower = fixture.actor(ctx, monsters.MONS_GNOLL, 8, 9, 12)
    local stone = equip(ctx, thrower, items.MI_STONE, slots.MISSILE)

    harness.truthy(events.apply(owner, player,
        ids.BAD_CHAOS_UPGRADE, 20, {
            stream = streams.RELIGION,
        }))

    local state = ctx:get(stone, component.ITEM)

    harness.equal(state.ego, missile_egos.CHAOS)
    inventory.validate(state, inventory.kind(state))
    projectiles.effect(items.MI_STONE).validate(state)

    -- An equally valid javelin uses the common thrown policy rather than
    -- failing when Xom adds the same saved Chaos ego.
    local javelin = projectiles.effect(items.MI_JAVELIN)

    harness.truthy(type(javelin.resolve) == "function")
    javelin.validate(state)

    -- Bows and slings also qualify as unbranded weapons. Their normal
    -- monster ranged validation must accept Xom's new weapon brand.
    projectiles.effect(items.MI_ARROW).validate_launcher({
        ego = weapon_brands.CHAOS,
    })
    projectiles.effect(items.MI_SLING_BULLET).validate_launcher({
        ego = weapon_brands.CHAOS,
    })
end

return test
