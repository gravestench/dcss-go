local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local choice = require("policy.combat.monster_summons.choice")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")

local effect = {}

-- The Wolf Spider weight rises with cast power; each other source weight
-- is fixed. This pool is built per cast because power belongs to the caster.
local function spider_pool(power)
    return {
        {
            id = monsters.MONS_REDBACK,
            weight = 100,
        },

        {
            id = monsters.MONS_JUMPING_SPIDER,
            weight = 100,
        },

        {
            id = monsters.MONS_TARANTELLA,
            weight = 75,
        },

        {
            id = monsters.MONS_CULICIVORA,
            weight = 50,
        },

        {
            id = monsters.MONS_ORB_SPIDER,
            weight = 50,
        },

        {
            id = monsters.MONS_WOLF_SPIDER,
            weight = math.floor(power / 2),
        },
    }
end
-- The spider pool's Wolf Spider weight depends on caster power;
-- resolve builds it after the caster is fixed by the plan.
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
    local pool = spider_pool(power)

    for _ = 1, count do
        summons.spawn(ctx, caster, spells.SPELL_SUMMON_SPIDERS,
            choice.weighted(ctx, pool), 3, nil)
    end
end

return effect
