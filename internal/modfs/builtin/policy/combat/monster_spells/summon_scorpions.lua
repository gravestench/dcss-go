local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")

local effect = {}

-- Scorpion count depends on caster power and two sequential draws;
-- both stay in resolution after the summoner is selected.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- Source div_rand_round sets a power-based maximum before the count draw.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local power = strength.power(ctx, caster, spells.SPELL_SUMMON_SCORPIONS)
    local max_count = 1 + roll.random_divide(ctx, power, 42,
        streams.MONSTER_SPELL)
    local count = 1 + roll.spell(ctx, max_count)

    for _ = 1, count do
        summons.spawn(ctx, caster, spells.SPELL_SUMMON_SCORPIONS,
            monsters.MONS_SCORPION, 2, nil)
    end
end

return effect
