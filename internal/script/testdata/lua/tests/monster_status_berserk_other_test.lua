-- Berserk Other incites an existing aligned monster, using the same saved
-- frenzy owner as a monster that casts Berserker Rage on itself.
local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local fixture = require("tests.fixtures.monster_status")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local test = {}

-- The ally stands nearer the player than its caster and within three cells.
-- An out-of-range ally is left alone even when its faction matches.
function test.run(ctx)
    local player = fixture.actor(ctx,
        monsters.MONS_GOBLIN, 4, 1, 30)

    ctx:add(player, component.PLAYER, {})

    local caster = fixture.actor(ctx,
        monsters.MONS_MOTH_OF_WRATH, 1, 1, 30)
    local ally = fixture.actor(ctx,
        monsters.MONS_ORC_WARRIOR, 2, 1, 20)
    local far_ally = fixture.actor(ctx,
        monsters.MONS_ORC_WARRIOR, 0, 6, 20)
    local live = fixture.context(ctx, player, 100)
    local effect = effects.effect(spells.SPELL_BERSERK_OTHER)
    local plan = effect.plan(live, caster, player)

    harness.truthy(plan, "one nearby ally makes the incitement useful")

    effect.resolve(live, caster, player, nil, plan)

    harness.truthy(allegiance.frenzied(ctx, ally),
        "the eligible ally uses the shared frenzy owner")
    harness.falsy(allegiance.frenzied(ctx, far_ally),
        "a distant ally cannot be incited")
    harness.falsy(effect.plan(live, caster, player),
        "a second cast declines when no eligible ally remains")
end

return test
