-- The live spell plans as a reckless self-centered chain, then resolves
-- each arc with the current caster power and the Chaos impact policy.
local actors = require("policy.combat.monster_area.actors")
local chain = require("policy.combat.monster_area.chain_of_chaos")
local effect = require("policy.combat.monster_spells.chain_of_chaos")
local harness = require("tests.harness")
local impact = require("policy.combat.monster_area.chaos_impact")
local power = require("policy.combat.monster_beams.power")
local self_target = require("policy.combat.monster_support.self_target")
local senses = require("policy.character.senses")
local targets = require("policy.ai.targets")

local test = {}
local caster = 11
local foe = 22

-- AI planning may reject an allied caster in player sight. The accepted
-- cast passes its live arc callback to the same topology used by tests.
function test.run()
    local saved = {
        los = actors.los,
        chain = chain.resolve,
        impact = impact.apply,
        power = power.caster_power,
        plan = self_target.plan,
        require = self_target.require_caster,
        sees = senses.player_sees_actor,
        allied = targets.allied,
        enemy = targets.enemy,
    }
    local observed = {
        strikes = 0,
    }
    local ctx = {}

    -- Cast messaging is irrelevant to this topology and registration test.
    function ctx:emit()
    end

    actors.los = function()
        return { foe }
    end

    senses.player_sees_actor = function()
        return true
    end

    targets.allied = function()
        return false
    end

    targets.enemy = function()
        return true
    end

    self_target.plan = function()
        return { caster = caster }
    end

    self_target.require_caster = function()
    end

    power.caster_power = function()
        return 17
    end

    impact.apply = function(_, source, _, target, arc_power)
        observed.strikes = observed.strikes + 1
        harness.equal(source, caster, "caster owns the Chaos contact")
        harness.equal(target, foe, "arc target reaches Chaos impact")
        harness.equal(arc_power, 17, "arc uses current spell power")
    end

    chain.resolve = function(context, source, current_power, strike)
        harness.equal(current_power, 17,
            "chain starts with monster spell power")
        strike(context, { level_id = 1, x = 0, y = 0 }, foe,
            current_power, false)
    end

    local plan = effect.plan(ctx, caster)

    harness.truthy(plan, "a hostile caster with a visible foe can cast")

    effect.resolve(ctx, caster, nil, nil, plan)

    harness.equal(observed.strikes, 1,
        "live spell connects chain topology to Chaos impact")

    targets.allied = function()
        return true
    end

    harness.equal(effect.plan(ctx, caster), nil,
        "an allied caster avoids visible friendly fire")

    actors.los = saved.los
    chain.resolve = saved.chain
    impact.apply = saved.impact
    power.caster_power = saved.power
    self_target.plan = saved.plan
    self_target.require_caster = saved.require
    senses.player_sees_actor = saved.sees
    targets.allied = saved.allied
    targets.enemy = saved.enemy
end

return test
