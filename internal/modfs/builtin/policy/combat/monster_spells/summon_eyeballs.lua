local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local eyeballs = require("policy.combat.monster_summons.eyeballs")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local spells = require("ids.spells")

local effect = {}

-- Eyeball kind is redrawn for each creature at cast time; planning
-- needs only the actor whose effective spell HD sets the count.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- The eye pool is redrawn per creature, while duration depends on caster HD.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local hd = strength.spell_hd(ctx, caster)
    local count = 1 + roll.spell(ctx, math.floor(hd / 7) + 1)
    local degree = math.min(2 + math.floor(hd / 10), 6)

    for _ = 1, count do
        summons.spawn(ctx, caster, spells.SPELL_SUMMON_EYEBALLS,
            eyeballs.pick(ctx), degree, nil)
    end
end

return effect
