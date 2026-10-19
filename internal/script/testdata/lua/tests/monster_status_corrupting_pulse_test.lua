-- A friendly caster's pulse corrupts an enemy monster through the same
-- Wretched owner used by Irradiate and mutagenic clouds.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local fixture = require("tests.fixtures.monster_status")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local test = {}

-- The player's friendly summon can affect a hostile goblin without also
-- mutating its allied player owner. The ECS Wretched timer must be saved.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {})

    local caster = fixture.actor(ctx,
        monsters.MONS_WRETCHED_STAR, 1, 1, 40)
    local enemy = fixture.actor(ctx,
        monsters.MONS_GOBLIN, 2, 1, 10)
    local neutral = fixture.actor(ctx,
        monsters.MONS_GOBLIN, 3, 1, 10)

    ctx:add(caster, component.SUMMON, {
        owner = player,
        source_id = spells.SPELL_SUMMON_SMALL_MAMMAL,
        attitude = attitudes.FRIENDLY,
        expires_aut = 500,
    })
    ctx:add(neutral, component.SUMMON, {
        owner = player,
        source_id = spells.SPELL_SUMMON_SMALL_MAMMAL,
        attitude = attitudes.NEUTRAL,
        expires_aut = 500,
    })

    local live = fixture.context(ctx, player, 100)
    local effect = effects.effect(spells.SPELL_CORRUPTING_PULSE)
    local plan = effect.plan(live, caster, enemy)

    harness.truthy(plan, "an enemy in sight makes the pulse useful")

    effect.resolve(live, caster, enemy, nil, plan)

    local wretched = ctx:get(enemy, component.WRETCHED)

    harness.truthy(wretched and wretched.remaining_aut > 0,
        "the enemy gains the shared Wretched component")
    harness.truthy(ctx:has(neutral, component.WRETCHED),
        "an unaligned neutral actor is also corrupted")
    harness.falsy(ctx:has(caster, component.WRETCHED),
        "the caster does not corrupt itself")
end

return test
