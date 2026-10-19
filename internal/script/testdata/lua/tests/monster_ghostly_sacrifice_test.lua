-- Ghostly Sacrifice picks an ally whose death creates a favorable blast,
-- consumes that ally, then damages enemies with negative energy.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local effects = require("policy.combat.monster_spells")
local bond = require("policy.combat.monster_injury_bond")

local test = {}

-- A no-threat butterfly still takes blast damage, but source targeting
-- adds no extra experience-weighted cost for sacrificing it.
local function harmless_donor(ctx, game, effect)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_SORCERER,
        20, 50, 500)
    local donor = fixture.actor(ctx, monsters.MONS_BUTTERFLY,
        22, 50, 10)
    local foe = fixture.actor(ctx, monsters.MONS_GNOLL,
        23, 50, 500)

    for _, entity in ipairs({ caster, donor }) do
        ctx:add(entity, component.VAULT_ACTOR_OVERRIDES, {
            attitude = attitudes.FRIENDLY,
        })
    end

    harness.truthy(effect.plan(game, caster, foe),
        "a harmless donor does not carry a threatening-monster cost")
end

-- The explicit donor cost uses the same HD scale as blast impact. A foe
-- only one HD stronger cannot repay a valuable allied body.
local function costly_donor(ctx, game, effect)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_SORCERER,
        20, 40, 500)
    local donor = fixture.actor(ctx, monsters.MONS_CENTAUR_WARRIOR,
        22, 40, 500)
    local foe = fixture.actor(ctx, monsters.MONS_ANACONDA,
        23, 40, 500)

    for _, entity in ipairs({ caster, donor }) do
        ctx:add(entity, component.VAULT_ACTOR_OVERRIDES, {
            attitude = attitudes.FRIENDLY,
        })
    end

    harness.falsy(effect.plan(game, caster, foe),
        "the donor's source sacrifice cost stays on the impact scale")
end

-- An undead foe cannot justify killing an ally for negative energy that
-- will not harm it, regardless of its high experience weight.
local function immune_foe(ctx, game, effect)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_SORCERER,
        20, 20, 500)
    local donor = fixture.actor(ctx, monsters.MONS_ORC_WARRIOR,
        22, 20, 40)
    local lich = fixture.actor(ctx, monsters.MONS_ANCIENT_LICH,
        23, 20, 500)

    for _, entity in ipairs({ caster, donor }) do
        ctx:add(entity, component.VAULT_ACTOR_OVERRIDES, {
            attitude = attitudes.FRIENDLY,
        })
    end

    harness.falsy(effect.plan(game, caster, lich),
        "negative-energy immunity makes the sacrifice pointless")
end

-- The explosion is centered on the chosen donor even when the enemy is
-- elsewhere, and the donor must die before blast contact is calculated.
function test.run(ctx)
    local game = fixture.observed_context(ctx)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_SORCERER,
        3, 3, 500)
    local donor = fixture.actor(ctx, monsters.MONS_ORC_WARRIOR,
        5, 3, 40)
    local enemy = fixture.actor(ctx, monsters.MONS_ORC_WARLORD,
        6, 3, 500)
    local lich = fixture.actor(ctx, monsters.MONS_ANCIENT_LICH,
        5, 4, 500)

    for _, entity in ipairs({ caster, donor }) do
        ctx:add(entity, component.VAULT_ACTOR_OVERRIDES, {
            attitude = attitudes.FRIENDLY,
        })
        ctx:add(entity, component.COMBAT, {
            shield_blocks = 0,
        })
    end

    ctx:add(enemy, component.COMBAT, {
        shield_blocks = 0,
    })

    function game:random()
        return 0
    end

    local effect = effects.effect(spells.SPELL_GHOSTLY_SACRIFICE)
    local plan = effect.plan(game, caster, enemy)

    harness.truthy(plan, "a favorable allied donor is selected")
    harness.equal(plan.entity, donor,
        "the blast is centered on the allied donor")

    bond.grant(game, donor, caster, 100)

    effect.resolve(game, caster, enemy, nil, plan)

    harness.equal(ctx:get(donor, component.HEALTH).current, 0,
        "the donor dies before the blast")
    harness.truthy(ctx:get(enemy, component.HEALTH).current < 500,
        "the radius-one negative blast damages its enemy")
    harness.truthy(ctx:has(enemy, component.MONSTER_DRAINED),
        "negative energy also drains the surviving enemy")
    harness.equal(ctx:get(lich, component.HEALTH).current, 500,
        "the radius-one blast does not harm an undead bystander")

    immune_foe(ctx, game, effect)
    costly_donor(ctx, game, effect)
    harmless_donor(ctx, game, effect)
end

return test
