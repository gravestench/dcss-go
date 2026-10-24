-- A blocked shot returns through its normal hit and brand logic, with the original shooter as defender.

local component = require("constants.component")
local fixture = require("tests.fixtures.ranged_reflection")
local harness = require("tests.harness")
local ids = require("ids.items")
local ranged_actions = require("policy.combat.ranged_actions")
local brands = require("constants.weapon_brands")
local armour_egos = require("constants.armour_egos")
local slug_dart = require("policy.combat.monster_spells.slug_dart")
local catalog = require("policy.catalog")
local monsters = require("ids.monsters")
local monster_defense = require("policy.combat.monster_defense")
local size = require("constants.size")
local stone_effect = require("policy.combat.monster_projectiles.stone")

local test = {}

-- A reflected stone must resolve a new hit against the monster, leaving the player untouched.
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

-- Without the amulet, the same shield roll consumes the shot without creating a return attack.
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

-- Equipment state at impact controls reflection; a carried but unequipped amulet has no effect.
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

-- Reflection can supply the block itself when no physical shield is equipped.
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

-- Shield and reflection rolls have a fixed order; a returned beam must not
-- reuse the original defender's block outcome.
local function beam_shield_roll_order(ctx)
    local battle = {}
    local bounds = {}

    -- Capture requested bounds to check the shield's two rolls precede the reflected-beam bypass roll.
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

-- A disabled shooter cannot use its equipped shield against a spell reflected back at it.
local function paralysed_shooter_cannot_block(ctx)
    local _, _, shooter = fixture.scene(ctx,
        ids.MI_STONE, true, monsters.MONS_DART_SLUG)
    local definition = catalog.get("monsters", monsters.MONS_DART_SLUG)

    fixture.enemy_shield(ctx, shooter)
    ctx:add(shooter, component.PARALYSIS, { remaining_aut = 10 })

    harness.equal(monster_defense.shield(ctx, shooter, definition), nil,
        "paralysed shooter cannot raise a shield against Slug Dart")
end

-- Reflection starts another attack roll, so a successful block need not damage the shooter.
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

-- Returned physical missiles skip the shooter's own shield and its block counter.
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

-- A lethal return is credited to the player even though the monster launched the stone.
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

-- Temporarily disable the projectile flag to show that shield success alone cannot return it.
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

-- The poison ego follows a returned dart onto the shooter only after the new hit succeeds.
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

-- A return miss must not apply the poisoned dart's contact effect to either side.
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

-- Preserve the sling's flaming brand when its bullet changes direction after a block.
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

-- Freezing emits a visible effect, while Vorpal still needs to carry damage through the return.
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

-- A returned Acid bullet uses the ordinary monster-target splash owner;
-- the original player block does not receive the launcher's corrosion.
local function reflected_acid_launcher(ctx)
    local battle, player, shooter = fixture.scene(ctx,
        ids.MI_SLING_BULLET, true)
    local launcher = fixture.launcher(ctx, shooter, brands.ACID)

    fixture.block_then_return(battle)
    ranged_actions.monster(battle, shooter, { item_id = launcher })

    harness.equal(ctx:get(player, component.HEALTH).current, 20,
        "reflecting an Acid bullet protects the player")

    local splashed = false

    for _, event in ipairs(battle.events()) do
        if event.text:find("splashed with acid", 1, true) then
            splashed = true
        end
    end

    harness.truthy(splashed,
        "Acid launcher effect follows the returned bullet")
end

-- A real monster-fired Acid shot reaches the player-facing brand owner
-- after contact, even without reflection or a special projectile ego.
local function monster_acid_launcher(ctx)
    local battle, player, shooter = fixture.scene(ctx,
        ids.MI_SLING_BULLET, false, nil, false)
    local launcher = fixture.launcher(ctx, shooter, brands.ACID)
    local draws = 0

    function battle.random(_, _, bound)
        draws = draws + 1

        if draws == 2 or draws == 3 then
            return 0
        end

        return bound - 1
    end

    ranged_actions.monster(battle, shooter, { item_id = launcher })

    local splashed = false
    local messages = {}

    for _, event in ipairs(battle.events()) do
        messages[#messages + 1] = event.text

        if event.text:find("You are splashed with acid!", 1, true) then
            splashed = true
        end
    end

    harness.truthy(splashed,
        "monster launcher routed Acid through the player brand owner: " ..
            table.concat(messages, " | "))
    harness.truthy(ctx:get(player, component.HEALTH).current < 20,
        "monster Acid launcher damaged the player")
end

-- Slug Dart's bespoke ranged path still has to use the common reflection
-- behavior after the player's shield blocks it.
local function reflected_slug_dart(ctx)
    local battle, player, shooter = fixture.scene(ctx, ids.MI_STONE,
        true, monsters.MONS_DART_SLUG)
    fixture.slug_dart_block_then_return(battle)
    local plan = slug_dart.plan(battle, shooter, player)

    slug_dart.resolve(battle, shooter, player, nil, plan)

    harness.equal(ctx:get(player, component.HEALTH).current, 20,
        "blocked Slug Dart does not hurt the player")
    harness.truthy(ctx:get(shooter, component.HEALTH).current < 40,
        "reflected Slug Dart can hurt its caster")
end

-- A monster foe uses its own shield against Slug Dart; the nearby player
-- has no shield and must not supply the defense snapshot for this cast.
local function monster_blocks_slug_dart(ctx)
    local battle, player, shooter = fixture.scene(ctx, ids.MI_STONE,
        false, monsters.MONS_DART_SLUG, false)
    local foe = ctx:create()

    ctx:add(foe, component.ACTOR, {
        kind_id = monsters.MONS_GOBLIN,
        speed = 10,
    })

    ctx:add(foe, component.HEALTH, {
        current = 40,
        max = 40,
    })

    ctx:add(foe, component.POSITION, {
        level_id = 1,
        x = 2,
        y = 1,
    })

    ctx:add(foe, component.COMBAT, { shield_blocks = 0 })
    local shield = fixture.enemy_shield(ctx, foe)

    local draws = 0

    -- High shield dice and a low bypass die force the monster's block.
    function battle.random(_, stream, bound)
        harness.equal(stream, "monster_spell", "Slug Dart stream")
        draws = draws + 1

        if draws <= 2 then
            return bound - 1
        end

        return 0
    end

    local plan = slug_dart.plan(battle, shooter, foe)

    -- A shield block still resolves offscreen without naming the monster.
    function battle.visible()
        return false
    end

    slug_dart.resolve(battle, shooter, foe, nil, plan)

    harness.equal(ctx:get(foe, component.HEALTH).current, 40,
        "monster shield prevents Slug Dart damage")
    harness.equal(ctx:get(foe, component.COMBAT).shield_blocks, 1,
        "the monster's own shield count advances")
    harness.equal(ctx:get(player, component.HEALTH).current, 20,
        "the cast leaves the player untouched")
    harness.equal(#battle.events(), 0,
        "offscreen monster shield block emits no target message")

    -- Once reflection is equipped, the same blocked shot returns toward
    -- its source; the nearby player remains outside that exchange.
    local shield_item = ctx:get(shield, component.ITEM)
    shield_item.ego = armour_egos.REFLECTION
    ctx:set(shield, component.ITEM, shield_item)
    draws = 0

    -- Restore nearby visibility for the reflected shot's message path.
    function battle.visible()
        return true
    end

    -- The player can see the reflecting shield but not the invisible
    -- original caster. The rebound must not name that hidden victim.
    ctx:add(shooter, component.MONSTER_ENCHANT, {
        invisible_aut = 100,
    })
    local messages_before = #battle.events()

    slug_dart.resolve(battle, shooter, foe, nil, plan)

    harness.truthy(ctx:get(shooter, component.HEALTH).current < 40,
        "monster reflection can hurt the Slug Dart caster")
    harness.equal(ctx:get(player, component.HEALTH).current, 20,
        "monster reflection does not credit damage to the player")
    harness.equal(#battle.events(), messages_before + 2,
        "reflection reports only the visible defender and rebound")
end

-- Slug Dart's return follows spell shield rules, allowing a capable original caster to block it.
local function slug_dart_return_blocked(ctx)
    local battle, player, shooter = fixture.scene(ctx, ids.MI_STONE,
        true, monsters.MONS_DART_SLUG)
    fixture.enemy_shield(ctx, shooter)
    fixture.slug_dart_block_twice(battle)
    local plan = slug_dart.plan(battle, shooter, player)

    slug_dart.resolve(battle, shooter, player, nil, plan)

    harness.equal(ctx:get(shooter, component.HEALTH).current, 40,
        "original shooter can block a returned Slug Dart")
    harness.equal(ctx:get(shooter, component.COMBAT).shield_blocks, 1,
        "blocked return increments its shield count")
end

-- Run the same reflection fixture through missile, launcher, and bespoke Slug Dart paths.
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
    reflected_acid_launcher(ctx)
    monster_acid_launcher(ctx)
    reflected_slug_dart(ctx)
    monster_blocks_slug_dart(ctx)
    slug_dart_return_blocked(ctx)
end

return test
