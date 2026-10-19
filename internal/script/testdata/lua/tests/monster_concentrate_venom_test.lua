local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local effects = require("policy.combat.monster_spells")
local spells = require("ids.spells")
local venom = require("policy.combat.monster_tactical.concentrate_venom")
local curare = require("policy.combat.monster_tactical.curare")
local poison_beam = require("policy.combat.monster_beams.poison")
local flavours = require("constants.beam_flavours")

local test = {}

-- Amaemon selects a poison-capable ally, then the saved enchant changes
-- its later attacks until the source protection-class duration expires.
function test.run(ctx)
    local caster = fixture.actor(ctx, monsters.MONS_AMAEMON, 10, 10)
    local ally = fixture.actor(ctx, monsters.MONS_ADDER, 12, 10)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 0, 0)
    local game = fixture.context(ctx, player)
    local effect = effects.effect(spells.SPELL_CONCENTRATE_VENOM)
    local plan = effect.plan(game, caster, player)

    harness.truthy(plan, "poison-capable ally permits Venom")
    harness.equal(plan.entity, ally, "Venom targets the useful ally")
    effect.resolve(game, caster, player, nil, plan)

    harness.truthy(venom.active(game, ally),
        "recipient owns a saved concentrated-venom enchant")
    harness.falsy(venom.active(game, caster),
        "caster does not enchant itself")
    harness.falsy(effect.plan(game, caster, player),
        "active Venom cannot be reapplied")

    local timer = ctx:get(ally, venom.component_id).remaining_aut

    harness.truthy(timer > 0, "Venom uses a positive duration")
    venom.tick(game, ally, timer)
    harness.falsy(venom.active(game, ally),
        "Venom expires after elapsed action aut")

    local victim = fixture.actor(ctx, monsters.MONS_ORC, 13, 10, 50)

    venom.grant(game, ally)
    harness.truthy(venom.active(game, ally), "regranted Venom is active")
    curare.apply(game, ally, victim)
    harness.truthy(ctx:get(victim, "projectile.poison"),
        "concentrated poison applies curare poison")
    harness.truthy(ctx:get(victim, "projectile.slow"),
        "concentrated poison also slows a living victim")
    harness.truthy(ctx:get(victim, component.HEALTH).current < 50,
        "curare causes asphyxiation damage")

    local beam_victim = fixture.actor(ctx, monsters.MONS_ORC, 14, 10, 50)

    game.random = function(_, stream, bound)
        if bound == 3 then
            return 1
        end

        return ctx:random(stream, bound)
    end
    poison_beam.before_damage(game, ally, beam_victim, {
        id = spells.SPELL_SPIT_POISON,
        flavour = flavours.BEAM_POISON,
    }, {
        dice = { count = 1, sides = 6 },
        damage = 3,
        after_armour = 3,
    })
    harness.truthy(ctx:get(beam_victim, "projectile.slow"),
        "concentrated Spit Poison converts its dose into curare")
end

return test
