local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local boons = require("policy.combat.monster_support.boons")
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local test = {}

-- Source Berserker Rage needs a capable melee monster and nearby foe.
-- Its saved frenzy then changes speed and blocks an immediate recast.
function test.run(ctx)
    local caster = ctx:create()
    local foe = ctx:create()

    ctx:add(caster, component.ACTOR, {
        kind_id = monsters.MONS_ORC_SORCERER,
        speed = 7,
    })

    ctx:add(caster, component.HEALTH, {
        current = 10,
        max = 11,
    })

    ctx:add(caster, component.PROJECTILE_SLOW, {
        base_speed = 10,
        remaining_aut = 50,
    })

    ctx:add(caster, component.MONSTER_MASS_ENCHANT, {
        fear_aut = 40,
        anguish_aut = 20,
    })

    ctx:add(caster, component.POSITION, {
        level_id = 1,
        x = 5,
        y = 5,
    })

    ctx:add(foe, component.POSITION, {
        level_id = 1,
        x = 6,
        y = 5,
    })

    local rage = effects.effect(spells.SPELL_BERSERKER_RAGE)
    local plan = rage.plan(ctx, caster, foe)

    harness.truthy(plan, "nearby foe permits Berserker Rage")

    rage.resolve(ctx, caster, foe, nil, plan)

    harness.truthy(allegiance.frenzied(ctx, caster),
        "Berserker Rage uses the existing frenzy owner")
    harness.equal(ctx:get(caster, component.HEALTH).current, 15,
        "Berserker Rage inflates current HP")
    harness.equal(ctx:get(caster, component.HEALTH).max, 17,
        "Berserker Rage inflates odd maximum HP")
    harness.falsy(ctx:has(caster, component.PROJECTILE_SLOW),
        "intentional berserk shakes off Slow")
    harness.equal(ctx:get(caster, component.ACTOR).speed, 10,
        "shaking off Slow restores base speed")
    harness.equal(ctx:get(caster,
        component.MONSTER_MASS_ENCHANT).fear_aut, 0,
        "intentional berserk clears Fear")
    harness.equal(ctx:get(caster,
        component.MONSTER_MASS_ENCHANT).anguish_aut, 20,
        "clearing Fear preserves independent Anguish")
    harness.falsy(rage.plan(ctx, caster, foe),
        "active frenzy cannot be recast")

    allegiance.tick(ctx, caster)

    harness.truthy(allegiance.frenzied(ctx, caster),
        "frenzy duration ages through the shared turn owner")

    allegiance.tick(ctx, caster, 1000)

    harness.falsy(allegiance.frenzied(ctx, caster),
        "Berserker Rage expires before fatigue")
    harness.equal(ctx:get(caster, component.HEALTH).current, 10,
        "expiration reverses current HP inflation")
    harness.equal(ctx:get(caster, component.HEALTH).max, 11,
        "expiration restores odd maximum HP")

    local other = ctx:create()

    ctx:add(other, component.ACTOR, {
        kind_id = monsters.MONS_ORC_SORCERER,
        speed = 10,
    })

    ctx:add(other, component.POSITION, {
        level_id = 1,
        x = 5,
        y = 5,
    })

    boons.haste(ctx, other, 30)

    harness.falsy(rage.plan(ctx, other, foe),
        "Haste prevents a new Berserker Rage cast")
end

return test
