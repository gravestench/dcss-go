-- Source monster reach is a live capability of attacks and equipment.
-- These cases use the production catalog and Akara item components.
local catalog = require("policy.catalog")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local items = require("ids.items")
local artefacts = require("ids.artefacts")
local flavours = require("constants.attack_flavours")
local attacks = require("constants.monster_attack_types")
local reach = require("policy.combat.monster_reach")
local route = require("policy.ai.route")
local sequence = require("policy.combat.monster_attack_sequence")

local test = {}

-- An equipped item can be removed between decisions. Reach must read its
-- current ECS owner and catalog skill on every decision, not on spawn.
local function equip(ctx, holder, kind_id, unique_id)
    local item = ctx:create()

    ctx:add(item, component.ITEM, {
        kind_id = kind_id,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(item, component.CARRIED_BY, {
        holder = holder,
    })
    ctx:add(item, component.EQUIPPED, {
        slot = "weapon",
    })

    if unique_id then
        ctx:add(item, component.ITEM_ARTEFACT, {
            kind = "unrand",
            unique_id = unique_id,
        })
    end

    return item
end

-- Tongue reaches two cells, while Rift reaches three through solid
-- blocking line of sight. Their individual slots set the round's limit.
local function natural(ctx)
    local frog = fixture.actor(ctx, monsters.MONS_GOLIATH_FROG,
        20, 30, 100)
    local starflower = fixture.actor(ctx, monsters.MONS_STARFLOWER,
        30, 30, 100)
    local frog_attack = catalog.get("monsters",
        monsters.MONS_GOLIATH_FROG).attacks[1]
    local star_attacks = catalog.get("monsters",
        monsters.MONS_STARFLOWER).attacks

    harness.equal(reach.range(ctx, frog), 2,
        "Tongue contributes source range two")
    harness.equal(reach.range(ctx, starflower), 3,
        "Rift contributes source range three")
    harness.truthy(reach.contact(ctx, frog, frog_attack, 1, 2),
        "Tongue slot contacts at two cells")
    harness.falsy(reach.contact(ctx, frog, frog_attack, 1, 3),
        "Tongue slot cannot contact at three cells")
    harness.truthy(reach.contact(ctx, starflower,
        star_attacks[1], 1, 3),
        "Rift slot contacts at three cells")
    harness.falsy(reach.contact(ctx, starflower,
        star_attacks[2], 2, 3),
        "ordinary Reach slot cannot contact at three cells")

    local origin = ctx:get(starflower, component.POSITION)
    local target = {
        level_id = 1,
        x = 33,
        y = 30,
    }

    harness.truthy(reach.can(ctx, starflower, origin, target),
        "Rift line permits three-cell contact")

    function ctx:visible_no_trans()
        return false
    end

    harness.falsy(reach.can(ctx, starflower, origin, target),
        "Rift cannot cross solid-blocking sight")

    ctx.visible_no_trans = nil

    -- Derived undead inherit the base attack through the shared sequence;
    -- AI must read that same effective contact rather than the zombie row.
    local zombie = fixture.actor(ctx, monsters.MONS_ZOMBIE,
        36, 30, 100)

    ctx:add(zombie, component.VAULT_ACTOR_OVERRIDES, {
        base_id = monsters.MONS_SNAPPING_TURTLE,
    })

    harness.equal(reach.range(ctx, zombie), 2,
        "turtle zombie inherits its base monster's Reach")
    local inherited = sequence.for_actor(ctx, zombie,
        catalog.get("monsters", monsters.MONS_ZOMBIE))

    harness.truthy(reach.contact(ctx, zombie,
        inherited[1].attack, 1, 2),
        "derived undead's preserved Reach slot can contact")
end

-- Polearms, the Lochaber axe, and the Rift artefact derive their reach
-- from the actual primary weapon, not from a monster species flag.
local function weapons(ctx)
    local orc = fixture.actor(ctx, monsters.MONS_ORC,
        40, 30, 100)
    local hit = {
        type_id = attacks.HIT,
        flavour_id = flavours.PLAIN,
        damage = 6,
    }

    harness.equal(reach.range(ctx, orc), 1,
        "unarmed orc has adjacency only")

    local spear = equip(ctx, orc, items.WPN_SPEAR)

    harness.equal(reach.range(ctx, orc), 2,
        "current polearm grants two-cell reach")
    harness.truthy(reach.contact(ctx, orc, hit, 1, 2),
        "weapon HIT uses its equipped polearm")

    local victim = fixture.actor(ctx, monsters.MONS_RAT,
        42, 30, 100)
    local origin = ctx:get(orc, component.POSITION)
    local target = ctx:get(victim, component.POSITION)
    local state = {
        target_x = target.x,
        target_y = target.y,
    }
    local intent = route.follow(ctx, orc, state, origin,
        target, victim, true)

    harness.equal(intent.kind, 2,
        "equipped polearm offers distant melee instead of movement")

    ctx:remove(spear, component.EQUIPPED)
    harness.equal(reach.range(ctx, orc), 1,
        "unequipping polearm immediately removes reach")
    intent = route.follow(ctx, orc, state, origin,
        target, victim, true)
    harness.equal(intent.kind, 1,
        "without polearm the same foe requires movement")

    local axe = equip(ctx, orc, items.WPN_BATTLEAXE,
        artefacts.UNRAND_LOCHABER_AXE)

    harness.equal(reach.range(ctx, orc), 2,
        "Lochaber reaches despite its axe skill")

    ctx:remove(axe, component.EQUIPPED)
    local rift = equip(ctx, orc, items.WPN_DEMON_TRIDENT,
        artefacts.UNRAND_RIFT)

    harness.equal(reach.range(ctx, orc), 3,
        "Rift artefact extends a polearm to three")
    harness.truthy(reach.contact(ctx, orc, hit, 1, 3),
        "Rift weapon HIT contacts at three cells")

    ctx:remove(rift, component.EQUIPPED)
end

-- Real projected bodies and real items share one Lua reach policy.
function test.run(ctx)
    local game = fixture.observed_context(ctx)

    natural(game)
    weapons(game)
end

return test
