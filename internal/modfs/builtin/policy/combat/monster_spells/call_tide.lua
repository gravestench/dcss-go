-- Ilsuiw calls a timed Shoals tide around her current position.
-- Source: mon-cast.cc:SPELL_CALL_TIDE and dgn-shoals.cc.
local branches = require("ids.branches")
local component = require("constants.component")
local roll = require("policy.combat.roll")
local self_target = require("policy.combat.monster_support.self_target")

local effect = {}
local STATE = "world.called_tide"
local BASELINE_DELAY = 10

function effect.plan(ctx, caster, foe)
    local position = ctx:get(caster, component.POSITION)
    local state = ctx:get(caster, STATE)

    if not position or not foe or
        ctx:level_branch(position.level_id) ~= branches.BRANCH_SHOALS or
        state and state.expires_aut > ctx:aut() then
        return nil
    end

    local destination = ctx:get(foe, component.POSITION)

    if not destination or destination.level_id ~= position.level_id then
        return nil
    end

    -- Source judges a water-bound pair as a poor cast. This port's planner
    -- has only possible/impossible, so preserve possibility for that case.
    return self_target.plan(caster)
end

function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local position = ctx:get(caster, component.POSITION)

    if not position or
        ctx:level_branch(position.level_id) ~= branches.BRANCH_SHOALS then
        return
    end

    -- random_range(80, 200, 2) averages two draws across the inclusive
    -- range. The enchantment clock is stored in aut for save continuation.
    local turns = 80 + roll.average_two(ctx, "monster_spell", 121)

    local next_state = {
        start_aut = ctx:aut(),
        expires_aut = ctx:aut() + BASELINE_DELAY * turns,
    }

    if ctx:has(caster, STATE) then
        ctx:set(caster, STATE, next_state)
    else
        ctx:add(caster, STATE, next_state)
    end

    ctx:emit("monster_spell", "A water chant calls the tide!")
end

return effect
