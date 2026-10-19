-- These two source spells change existing actor state instead of causing
-- direct HP loss. Real ECS components make restore-visible effects observable
-- without restating their production schemas in this test.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local malmutation_rule = require("policy.combat.monster_hexes.malmutate")
local monsters = require("ids.monsters")
local afflictions = require("policy.combat.monster_spells")
local enchant = require("policy.combat.monster_enchant")
local player_corrosion = require("policy.combat.player_corrosion")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")
local jewellery_fixture = require("tests.fixtures.jewellery")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local test = {}

-- A friendly caster sees a hostile monster across open floor. The same
-- target plan that live AI writes is resolved by the real spell module.
local function actors(ctx)
    local game = fixture.observed_context(ctx)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_WIZARD,
        20, 20, 50)
    local target = fixture.actor(ctx, monsters.MONS_RAT,
        23, 20, 50)

    ctx:add(caster, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })

    function game:random()
        return 0
    end

    return game, caster, target
end

-- Malmutate is an irresistible targeted ray. A living monster acquires
-- the same Wretched component that Irradiate already uses.
local function malmutate(ctx, game, caster, target)
    local effect = afflictions.effect(spells.SPELL_MALMUTATE)
    local plan = effect.plan(game, caster, target)

    harness.truthy(plan, "Malmutate can plan an enemy target")
    effect.resolve(game, caster, target, nil, plan)
    harness.truthy(ctx:has(target, component.WRETCHED),
        "Malmutate stores Wretched on a mutable monster")

    local undead = fixture.actor(ctx, monsters.MONS_ZOMBIE,
        24, 20, 50)

    harness.falsy(malmutation_rule.viable(game, caster, undead),
        "an undead body cannot receive Malmutate")
end

-- Entropic Weave targets one actor without a projectile or damage roll.
-- Monster corrosion keeps its source status owner and lifetime.
local function entropic_weave(ctx, game, caster, target)
    local effect = afflictions.effect(spells.SPELL_ENTROPIC_WEAVE)
    local plan = effect.plan(game, caster, target)
    local before = ctx:get(target, component.HEALTH).current

    harness.truthy(plan, "Entropic Weave can plan an enemy target")
    effect.resolve(game, caster, target, nil, plan)
    harness.truthy(ctx:has(target, component.MONSTER_ENCHANT),
        "Entropic Weave applies saved monster corrosion")
    harness.equal(ctx:get(target, component.HEALTH).current, before,
        "Entropic Weave deals no direct damage")
end

-- Source-valid acid dragon body armour and a preservation cloak protect
-- monsters and players with the same one-in-two rCorr roll.
local function equipped_resistance(ctx, game)
    local monster = fixture.actor(ctx, monsters.MONS_ORC_WARRIOR,
        27, 20, 50)
    local monster_armour = jewellery_fixture.carry(ctx, monster,
        item_ids.ARM_ACID_DRAGON_ARMOUR)

    ctx:add(monster_armour, component.EQUIPPED, { slot = "body" })

    local definition = catalog.get(categories.MONSTERS,
        monsters.MONS_ORC_WARRIOR)

    harness.falsy(enchant.corrode_equipment(game, monster,
        definition, "The entropic weave"),
        "worn acid dragon armour gives a monster its rCorr save")
    harness.falsy(ctx:has(monster, component.MONSTER_ENCHANT),
        "resisted monster corrosion leaves no status")

    local player_ctx, player = jewellery_fixture.player(ctx)
    local player_cloak = jewellery_fixture.carry(ctx, player,
        item_ids.ARM_CLOAK)
    local player_cloak_state = ctx:get(player_cloak, component.ITEM)

    player_cloak_state.ego = armour_egos.PRESERVATION
    ctx:set(player_cloak, component.ITEM, player_cloak_state)
    ctx:add(player_cloak, component.EQUIPPED, { slot = "cloak" })

    function player_ctx.random()
        return 0
    end

    harness.falsy(player_corrosion.corrode_equipment(player_ctx,
        player, "The entropic weave"),
        "worn preservation gives a player its rCorr save")
    harness.falsy(ctx:has(player, component.CORROSION),
        "resisted player corrosion leaves no status")
end

-- Both effects resolve through the ordinary monster spell registry, so an
-- imported book slot can use them without a special Go handler.
function test.run(ctx)
    local game, caster, target = actors(ctx)

    malmutate(ctx, game, caster, target)
    entropic_weave(ctx, game, caster, target)
    equipped_resistance(ctx, game)
end

return test
