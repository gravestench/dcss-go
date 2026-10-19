local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local effects = require("policy.combat.monster_spells")
local spells = require("ids.spells")

local test = {}

-- A source Cantrip spends a real spell action while leaving both actors
-- unchanged; it is useful only while the caster has a foe.
local function cantrip(ctx)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_PRIEST, 10, 10)
    local foe = fixture.actor(ctx, monsters.MONS_HUMAN, 11, 10)
    local game = fixture.context(ctx, foe)
    local effect = effects.effect(spells.SPELL_CANTRIP)
    local plan = effect.plan(game, caster, foe)
    local before = ctx:get(foe, component.HEALTH).current

    harness.truthy(plan, "Cantrip has a foe-centered action")
    effect.resolve(game, caster, foe, nil, plan)
    harness.equal(ctx:get(foe, component.HEALTH).current, before,
        "Cantrip is harmless")
    harness.falsy(effect.plan(game, caster, nil),
        "Cantrip needs a foe")
end

-- Exercise real registered component schemas and spell lookup.
function test.run(ctx)
    cantrip(ctx)
end

return test
