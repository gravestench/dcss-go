-- Monster Silence tests the production spell and combined world field.
-- Position and timer changes must alter action answers without a cell cache.
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local fixture = require("tests.fixtures.monster_status")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local silence = require("policy.world.silence")
local spells = require("ids.spells")

local test = {}

-- The enchanted caster silences nearby cells until expiry; an innate
-- spectre has its own field that ends when it dies.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {})

    local caster = fixture.actor(ctx,
        monsters.MONS_ORC_SORCERER, 1, 1, 30)
    local spectre = fixture.actor(ctx,
        monsters.MONS_SILENT_SPECTRE, 30, 30, 20)
    local live = fixture.context(ctx, player, 0)
    local effect = effects.effect(spells.SPELL_SILENCE)
    local plan = effect.plan(live, caster, player)

    harness.truthy(plan, "a caster without an aura may cast Silence")

    effect.resolve(live, caster, player, nil, plan)

    local aura = ctx:get(caster, component.MONSTER_SILENCE)

    harness.truthy(aura and aura.remaining_aut > 0,
        "the caster owns a saved aura timer")
    harness.truthy(silence.at(live, 1, 2, 1),
        "the aura covers a nearby cell")
    harness.falsy(silence.at(live, 1, 15, 15),
        "the aura does not cover distant cells")
    harness.falsy(effect.plan(live, caster, player),
        "an active aura blocks a redundant cast")

    silence.tick(live, caster, aura.remaining_aut)

    harness.falsy(ctx:has(caster, component.MONSTER_SILENCE),
        "the enchanted aura expires on its owner's action")
    harness.falsy(silence.at(live, 1, 2, 1),
        "expiry clears the nearby silence field")
    harness.truthy(silence.at(live, 1, 30, 30),
        "a living Silent Spectre has an innate field")

    local health = ctx:get(spectre, component.HEALTH)

    health.current = 0
    ctx:set(spectre, component.HEALTH, health)

    harness.falsy(silence.at(live, 1, 30, 30),
        "a dead spectre no longer silences its cell")
end

return test
