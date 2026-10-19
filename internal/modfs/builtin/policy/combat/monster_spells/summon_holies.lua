local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local holies = require("policy.combat.monster_summons.holies")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local spells = require("ids.spells")

local effect = {}

-- Holy kind and two count rolls are cast effects, so the plan stores
-- only the caster and spends no random draws.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- The two count draws stay separate as in the source sequence point.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local hd = strength.spell_hd(ctx, caster)
    local count = 1 + roll.spell(ctx, 2)

    count = count + roll.spell(ctx, math.floor(hd / 4) + 1)

    local degree = math.min(2 + math.floor(hd / 5), 6)

    for _ = 1, count do
        summons.spawn(ctx, caster, spells.SPELL_SUMMON_HOLIES,
            holies.pick(ctx), degree, nil)
    end
end

return effect
