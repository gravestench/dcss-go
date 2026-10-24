local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local spiders = require("policy.combat.monster_summons.spiders")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")

local effect = {}

-- Self-targeted spell plans keep its later placement at the caster.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- A power roll is stochastically divided by 80 to set the spider count.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local power = strength.power(ctx, caster,
        spells.SPELL_SUMMON_SPIDERS)
    local count = 1 + roll.random_divide(ctx,
        roll.spell(ctx, power), 80, streams.MONSTER_SPELL)

    for _ = 1, count do
        summons.spawn(ctx, caster, spells.SPELL_SUMMON_SPIDERS,
            spiders.pick(ctx, power), 3, nil)
    end
end

return effect
