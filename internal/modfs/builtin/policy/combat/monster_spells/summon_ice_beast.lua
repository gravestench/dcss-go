local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- The Ice Beast is born beside its summoner, with its source degree
-- determined at resolution rather than through foe targeting.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- The source _summon helper creates one Ice Beast at degree five.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    summons.spawn(ctx, caster, spells.SPELL_SUMMON_ICE_BEAST,
        monsters.MONS_ICE_BEAST, 5, nil)
end

return effect
