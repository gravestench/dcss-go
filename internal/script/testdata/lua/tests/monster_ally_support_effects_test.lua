local boons = require("policy.combat.monster_support.boons")
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local test = {}

-- The planner must spend no cast on a recipient whose relevant boon is
-- already active, while a different beneficial spell remains available.
local function test_boons(game, caster, target)
    local haste = effects.effect(spells.SPELL_HASTE_OTHER)
    local might = effects.effect(spells.SPELL_MIGHT_OTHER)
    local haste_plan = haste.plan(game, caster)

    harness.equal(haste_plan.entity, target,
        "Haste Other selects the allied monster")
    haste.resolve(game, caster, nil, nil, haste_plan)

    harness.truthy(boons.hasted(game, target),
        "Haste Other writes the target's shared speed boon")
    harness.equal(boons.speed(game, target, 10), 15,
        "the existing speed consumer reads allied Haste")
    harness.falsy(boons.hasted(game, caster),
        "Haste Other does not bless its caster")
    harness.falsy(haste.plan(game, caster),
        "active Haste cannot receive another source Haste beam")

    local might_plan = might.plan(game, caster)

    harness.equal(might_plan.entity, target,
        "Might Other can still choose the hasted ally")
    might.resolve(game, caster, nil, nil, might_plan)

    harness.truthy(boons.mighty(game, target),
        "Might Other writes the target's shared melee boon")
    harness.equal(boons.damage(game, target, 10), 15,
        "the existing melee consumer reads allied Might")
    harness.falsy(might.plan(game, caster),
        "active Might cannot receive another source Might beam")
end

-- Invisibility Other must use the same enchant component that perception
-- and expiry already read, preserving unrelated enchant fields.
local function test_invisibility(game, caster, target)
    local invisibility = effects.effect(spells.SPELL_INVISIBILITY_OTHER)

    game:add(target, component.MONSTER_ENCHANT, {
        blind_aut = 7,
        corrosion_aut = 0,
        invisible_aut = 0,
    })

    local plan = invisibility.plan(game, caster)

    harness.equal(plan.entity, target,
        "Invisibility Other selects an uncovered ally")
    invisibility.resolve(game, caster, nil, nil, plan)

    local enchant = game:get(target, component.MONSTER_ENCHANT)

    harness.truthy(enchant.invisible_aut > 0,
        "recipient becomes invisible in the shared enchant owner")
    harness.equal(enchant.blind_aut, 7,
        "invisibility preserves unrelated monster enchantments")
    harness.falsy(invisibility.plan(game, caster),
        "already invisible monster is not targeted again")
end

-- The source checks any missing HP, even one point, and heals the recipient
-- with the caster's Minor Healing dice rather than the recipient's HD.
local function test_healing(game, caster, target)
    local healing = effects.effect(spells.SPELL_HEAL_OTHER)
    local health = game:get(target, component.HEALTH)

    health.current = health.max - 1
    game:set(target, component.HEALTH, health)

    local plan = healing.plan(game, caster)

    harness.equal(plan.entity, target,
        "Heal Other considers a one-HP wound")
    healing.resolve(game, caster, nil, nil, plan)

    harness.equal(game:get(target, component.HEALTH).current, health.max,
        "recipient healing clamps at maximum HP")
    harness.falsy(healing.plan(game, caster),
        "a fully healed ally is not targeted")

    health.current = 50
    game:set(target, component.HEALTH, health)

    local second_plan = healing.plan(game, caster)

    healing.resolve(game, caster, nil, nil, second_plan)

    local result = game:get(target, component.HEALTH).current

    harness.truthy(result >= 55 and result <= 61,
        "the caster's HD-nine Minor Healing beam adds three plus two d4")
    harness.equal(game:get(caster, component.HEALTH).current, 10,
        "Heal Other does not change the caster's health")
end

-- Each source spell family operates on the same live ECS entities but
-- resolves through its own small spell module and shared state owner.
function test.run(ctx)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_SORCERER, 3, 3)
    local target = fixture.actor(ctx, monsters.MONS_ORC_WARRIOR, 4, 3)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 8, 8)
    local game = fixture.context(ctx, player)

    test_boons(game, caster, target)
    test_invisibility(game, caster, target)
    test_healing(game, caster, target)
end

return test
