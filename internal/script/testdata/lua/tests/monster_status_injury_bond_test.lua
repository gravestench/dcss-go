-- Injury Bond must save the protector and split real combat damage through
-- the production monster health owner, not merely decorate the spell cast.
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local fixture = require("tests.fixtures.monster_status")
local harness = require("tests.harness")
local health = require("policy.combat.monster_health")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local test = {}

-- Two allies get independent saved bonds. A nine-point strike redirects
-- four points, and killing the protector stops later redirection.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {})

    local caster = fixture.actor(ctx,
        monsters.MONS_ORC_SORCERER, 1, 1, 30)
    local ally = fixture.actor(ctx,
        monsters.MONS_ORC_WARRIOR, 2, 1, 20)
    local other = fixture.actor(ctx,
        monsters.MONS_GOBLIN, 3, 1, 20)
    local live = fixture.context(ctx, player, 100)
    local effect = effects.effect(spells.SPELL_INJURY_BOND)
    local plan = effect.plan(live, caster, player)

    harness.truthy(plan, "eligible allies make the cast useful")

    effect.resolve(live, caster, player, nil, plan)

    harness.truthy(ctx:has(ally, component.MONSTER_INJURY_BOND),
        "first ally saves its protector")
    harness.truthy(ctx:has(other, component.MONSTER_INJURY_BOND),
        "second ally saves an independent timer")

    health.damage(live, ally, 9, player)

    harness.equal(ctx:get(ally, component.HEALTH).current, 15,
        "the ally loses five of nine damage")
    harness.equal(ctx:get(caster, component.HEALTH).current, 26,
        "the protector accepts the other four")

    health.damage(live, caster, 50, nil)
    health.damage(live, ally, 9, nil)

    harness.equal(ctx:get(ally, component.HEALTH).current, 6,
        "a dead protector no longer receives redirected damage")
end

return test
