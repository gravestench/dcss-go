local component = require("constants.component")
local fixture = require("tests.fixtures.ranged_reflection")
local harness = require("tests.harness")
local ids = require("ids.items")
local ranged_actions = require("policy.combat.ranged_actions")
local brands = require("constants.weapon_brands")
local slug_dart = require("policy.combat.monster_spells.slug_dart")
local catalog = require("policy.catalog")
local monsters = require("ids.monsters")
local monster_defense = require("policy.combat.monster_defense")
local size = require("constants.size")
local stone_effect = require("policy.combat.monster_projectiles.stone")

local test = {}

local function stone_bounce(ctx)
    local battle, player, shooter, missile = fixture.scene(ctx,
        ids.MI_STONE, true)

    fixture.block_then_return(battle)

    ranged_actions.monster(battle, shooter, { item_id = missile })

    harness.equal(ctx:get(player, component.HEALTH).current, 20,
        "the blocked stone does not hurt the player")
    harness.truthy(ctx:get(shooter, component.HEALTH).current < 40,
        "a reflected stone can hurt its original shooter")
end

local function ordinary_block(ctx)
    local battle, player, shooter, missile = fixture.scene(ctx,
        ids.MI_STONE, false)

    fixture.block_then_return(battle)

    ranged_actions.monster(battle, shooter, { item_id = missile })

    harness.equal(ctx:get(player, component.HEALTH).current, 20,
        "ordinary shield blocks the stone")
    harness.equal(ctx:get(shooter, component.HEALTH).current, 40,
        "ordinary shield does not return the stone")
end

local function removed_reflector(ctx)
    local battle, player, shooter, missile, amulet = fixture.scene(ctx,
        ids.MI_STONE, true)

    ctx:remove(amulet, component.EQUIPPED)
    fixture.block_then_return(battle)
    ranged_actions.monster(battle, shooter, { item_id = missile })

    harness.equal(ctx:get(player, component.HEALTH).current, 20,
        "shield still blocks after removing the amulet")
    harness.equal(ctx:get(shooter, component.HEALTH).current, 40,
        "removed reflector cannot return the stone")
end

local function reflector_without_shield(ctx)
    local battle, player, shooter, missile = fixture.scene(ctx,
        ids.MI_STONE, true, nil, false)

    fixture.block_then_return(battle)
    ranged_actions.monster(battle, shooter, { item_id = missile })

    harness.equal(ctx:get(player, component.HEALTH).current, 20,
        "reflector blocks a stone without a physical shield")
    harness.truthy(ctx:get(shooter, component.HEALTH).current < 40,
        "shieldless reflector returns the stone")
end

local function beam_shield_roll_order(ctx)
    local battle = {}
    local bounds = {}

    function battle.random(_, _, bound)
        bounds[#bounds + 1] = bound

        if #bounds <= 2 then
            return bound - 1
        end

        return 0
    end

    monster_defense.beam_block(battle, {
        ac = 4,
        plus = 0,
        subtype = 14,
        size = size.MEDIUM,
        hit_dice = 1,
        blocks = 0,
    }, 14)

    harness.equal(bounds[1], 9,
        "monster shield rolls before reflected beam bypass")
    harness.equal(bounds[2], 10,
        "monster shield uses both average rolls")
    harness.equal(bounds[3], 18,
        "reflected beam bypass rolls after shield bonus")
end

local function paralysed_shooter_cannot_block(ctx)
    local _, _, shooter = fixture.scene(ctx,
        ids.MI_STONE, true, monsters.MONS_DART_SLUG)
    local definition = catalog.get("monsters", monsters.MONS_DART_SLUG)

    fixture.enemy_shield(ctx, shooter)
    ctx:add(shooter, component.PARALYSIS, { remaining_aut = 10 })

    harness.equal(monster_defense.shield(ctx, shooter, definition), nil,
        "paralysed shooter cannot raise a shield against Slug Dart")
end

local function returned_stone_misses(ctx)
    local battle, player, shooter, missile = fixture.scene(ctx,
        ids.MI_STONE, true)

    fixture.block_then_return(battle, false)
    ranged_actions.monster(battle, shooter, { item_id = missile })

    harness.equal(ctx:get(player, component.HEALTH).current, 20,
        "player still blocks a returned miss")
    harness.equal(ctx:get(shooter, component.HEALTH).current, 40,
        "return trajectory can miss its shooter")
end

local function returned_stone_cannot_self_block(ctx)
    local battle, _, shooter, missile = fixture.scene(ctx,
        ids.MI_STONE, true)

    fixture.enemy_shield(ctx, shooter)
    fixture.block_then_return(battle)
    ranged_actions.monster(battle, shooter, { item_id = missile })

    harness.truthy(ctx:get(shooter, component.HEALTH).current < 40,
        "shooter cannot block its own returned stone")
    harness.equal(ctx:get(shooter, component.COMBAT).shield_blocks, 0,
        "self-directed return cannot advance shield count")
end

local function returned_stone_kills(ctx)
    local battle, _, shooter, missile = fixture.scene(ctx,
        ids.MI_STONE, true)

    ctx:set(shooter, component.HEALTH, {
        current = 1,
        max = 40,
    })
    fixture.block_then_return(battle)
    ranged_actions.monster(battle, shooter, { item_id = missile })

    harness.equal(ctx:get(shooter, component.HEALTH).current, 0,
        "reflected stone can kill its original shooter")
    local player_kill = false

    for _, signal in ipairs(battle.signals()) do
        if signal.kind == "player_kill" and signal.target == shooter then
            player_kill = true
        end
    end

    harness.truthy(player_kill,
        "reflected kill is attributed to the player")
end

local function nonreflectable_stone(ctx)
    local battle, _, shooter, missile = fixture.scene(ctx,
        ids.MI_STONE, true)
    local previous = stone_effect.reflectable

    stone_effect.reflectable = false
    fixture.block_then_return(battle)
    ranged_actions.monster(battle, shooter, { item_id = missile })
    stone_effect.reflectable = previous

    harness.equal(ctx:get(shooter, component.HEALTH).current, 40,
        "nonreflectable projectiles stop at the shield")
end

local function reflected_dart(ctx)
    local battle, player, shooter, missile = fixture.scene(ctx,
        ids.MI_DART, true)

    fixture.block_then_return(battle)
    ranged_actions.monster(battle, shooter, { item_id = missile })

    harness.equal(ctx:get(player, component.HEALTH).current, 20,
        "blocked poisoned dart does not hurt the player")
    harness.truthy(ctx:has(shooter, component.PROJECTILE_POISON),
        "reflected poisoned dart poisons its shooter")
end

local function missed_dart_does_not_poison(ctx)
    local battle, player, shooter, missile = fixture.scene(ctx,
        ids.MI_DART, true)

    fixture.block_then_return(battle, false)
    ranged_actions.monster(battle, shooter, { item_id = missile })

    harness.equal(ctx:get(player, component.HEALTH).current, 20,
        "inbound poisoned dart was blocked")
    harness.falsy(ctx:has(shooter, component.PROJECTILE_POISON),
        "a missed return cannot poison the shooter")
end

local function reflected_launcher(ctx)
    local battle, player, shooter = fixture.scene(ctx,
        ids.MI_SLING_BULLET, true)
    local launcher = fixture.launcher(ctx, shooter, brands.FLAMING)

    fixture.block_then_return(battle)
    ranged_actions.monster(battle, shooter, { item_id = launcher })

    harness.equal(ctx:get(player, component.HEALTH).current, 20,
        "blocked sling bullet does not hurt the player")
    harness.truthy(ctx:get(shooter, component.HEALTH).current < 40,
        "reflected sling bullet hurts its shooter")

    local burned = false

    for _, event in ipairs(battle.events()) do
        if event.text:find("burns the goblin", 1, true) then
            burned = true
        end
    end

    harness.truthy(burned,
        "launcher brand affects the monster hit by its returned bullet")
end

local function other_launcher_brands(ctx)
    for _, brand in ipairs({ brands.FREEZING, brands.VORPAL }) do
        local battle, _, shooter = fixture.scene(ctx,
            ids.MI_SLING_BULLET, true)
        local launcher = fixture.launcher(ctx, shooter, brand)

        fixture.block_then_return(battle)
        ranged_actions.monster(battle, shooter, { item_id = launcher })

        harness.truthy(ctx:get(shooter, component.HEALTH).current < 40,
            "returned " .. brand .. " bullet hurts its shooter")

        if brand == brands.FREEZING then
            local froze = false

            for _, event in ipairs(battle.events()) do
                if event.text:find("freezes the goblin", 1, true) then
                    froze = true
                end
            end

            harness.truthy(froze,
                "freezing brand applies to the returned bullet")
        end
    end
end

local function reflected_slug_dart(ctx)
    local battle, player, shooter = fixture.scene(ctx, ids.MI_STONE,
        true, monsters.MONS_DART_SLUG)
    local definition = catalog.get("monsters", monsters.MONS_DART_SLUG)

    fixture.slug_dart_block_then_return(battle)
    slug_dart.resolve(battle, shooter, nil, definition,
        ctx:get(player, component.HEALTH))

    harness.equal(ctx:get(player, component.HEALTH).current, 20,
        "blocked Slug Dart does not hurt the player")
    harness.truthy(ctx:get(shooter, component.HEALTH).current < 40,
        "reflected Slug Dart can hurt its caster")
end

local function slug_dart_return_blocked(ctx)
    local battle, player, shooter = fixture.scene(ctx, ids.MI_STONE,
        true, monsters.MONS_DART_SLUG)
    local definition = catalog.get("monsters", monsters.MONS_DART_SLUG)

    fixture.enemy_shield(ctx, shooter)
    fixture.slug_dart_block_twice(battle)
    slug_dart.resolve(battle, shooter, nil, definition,
        ctx:get(player, component.HEALTH))

    harness.equal(ctx:get(shooter, component.HEALTH).current, 40,
        "original shooter can block a returned Slug Dart")
    harness.equal(ctx:get(shooter, component.COMBAT).shield_blocks, 1,
        "blocked return increments its shield count")
end

function test.run(ctx)
    stone_bounce(ctx)
    ordinary_block(ctx)
    removed_reflector(ctx)
    reflector_without_shield(ctx)
    beam_shield_roll_order(ctx)
    paralysed_shooter_cannot_block(ctx)
    returned_stone_misses(ctx)
    returned_stone_cannot_self_block(ctx)
    returned_stone_kills(ctx)
    nonreflectable_stone(ctx)
    reflected_dart(ctx)
    missed_dart_does_not_poison(ctx)
    reflected_launcher(ctx)
    other_launcher_brands(ctx)
    reflected_slug_dart(ctx)
    slug_dart_return_blocked(ctx)
end

return test
