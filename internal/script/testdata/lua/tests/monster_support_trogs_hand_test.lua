local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local hand = require("policy.combat.monster_support.trogs_hand")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local fixture = require("tests.monster_ally_support_fixture")

local test = {}

-- The invocation grants one saved duration for both regeneration and strong
-- will; expiry must remove both effects in the same actor action.
function test.run(ctx)
    local game = fixture.observed_context(ctx)
    local caster = ctx:create()

    ctx:add(caster, component.ACTOR, {
        kind_id = monsters.MONS_ORC_SORCERER,
        speed = 10,
    })

    local effect = effects.effect(spells.SPELL_TROGS_HAND)
    local plan = effect.plan(game, caster)

    harness.truthy(plan, "Trog's Hand can be invoked while absent")

    effect.resolve(game, caster, nil, nil, plan)

    harness.truthy(hand.active(ctx, caster),
        "Trog's Hand persists as actor-owned state")
    harness.equal(hand.will_bonus(ctx, caster), 80,
        "strong will adds the source resistance bonus")
    harness.equal(ctx:get(caster, component.MONSTER_TROGS_HAND).remaining_aut,
        70, "the source HD-nine minimum duration is seven turns")
    harness.falsy(effect.plan(ctx, caster),
        "active protection cannot be invoked again")

    hand.tick(ctx, caster, 70)

    harness.falsy(hand.active(ctx, caster),
        "regeneration and strong will expire together")
    harness.equal(hand.will_bonus(ctx, caster), 0,
        "expired protection no longer changes willpower")
end

return test
