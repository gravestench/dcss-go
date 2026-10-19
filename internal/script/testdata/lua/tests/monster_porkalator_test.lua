local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local effects = require("policy.combat.monster_spells")
local pork = require("policy.combat.monster_hexes.porkalator")
local death_hooks = require("policy.combat.death_hooks")
local catalog = require("policy.catalog")

local test = {}

function test.run(ctx)
    local caster = fixture.actor(ctx, monsters.MONS_KIRKE, 8, 8)
    local target = fixture.actor(ctx, monsters.MONS_ORC, 9, 8, 50)
    local game = fixture.context(ctx, target)
    local effect = effects.effect(spells.SPELL_PORKALATOR)

    harness.truthy(effect.plan(game, caster, target),
        "Kirke can target a natural monster")
    harness.truthy(pork.viable(game, caster, target),
        "natural monster is porkalator-eligible")
    pork.apply(game, caster, target, { cap = 100 })
    harness.equal(ctx:get(target, component.ACTOR).kind_id,
        monsters.MONS_HOG, "natural monster becomes a hog")
    harness.equal(ctx:get(target, component.MONSTER_POLYMORPH)
        .original_kind_id, monsters.MONS_ORC,
        "pig transformation preserves original kind for reversion")
    harness.falsy(pork.viable(game, caster, target),
        "hog cannot be porkalated again")

    local demon = fixture.actor(ctx, monsters.MONS_APOCALYPSE_CRAB,
        10, 8, 50)
    local holy = fixture.actor(ctx, monsters.MONS_ANGEL, 11, 8, 50)

    pork.apply(game, caster, demon, { cap = 100 })
    pork.apply(game, caster, holy, { cap = 100 })
    harness.equal(ctx:get(demon, component.ACTOR).kind_id,
        monsters.MONS_HELL_HOG, "demonic monster becomes a hell hog")
    harness.equal(ctx:get(holy, component.ACTOR).kind_id,
        monsters.MONS_HOLY_SWINE, "holy monster becomes holy swine")

    death_hooks.run(game, caster,
        catalog.get("monsters", monsters.MONS_KIRKE),
        ctx:get(caster, component.POSITION), true)
    harness.equal(ctx:get(target, component.ACTOR).kind_id,
        monsters.MONS_ORC, "Kirke's death restores the original kind")
    harness.equal(ctx:get(demon, component.ACTOR).kind_id,
        monsters.MONS_APOCALYPSE_CRAB,
        "Kirke's death restores demonic original")
    harness.equal(ctx:get(holy, component.ACTOR).kind_id,
        monsters.MONS_ANGEL, "Kirke's death restores holy original")
end

return test
